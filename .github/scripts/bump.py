#!/usr/bin/env python3
"""Sync the Tokcos Chocolatey packages in this repository with the latest upstream release.

Invoked by .github/workflows/bump-packages.yml.

Checksum policy
---------------
The *served artifact* is the source of truth for every checksum written here,
because that is what `choco install` downloads and validates.  Upstream
`latest.json` supplies the version and is cross-checked, but it has been observed
to be wrong -- tokscos-cli 0.5.9 advertises a win32-x64 `archive` hash and `size`
that do not match the zip actually served.  Such a disagreement is surfaced as a
GitHub warning rather than being silently trusted or silently ignored.

Beware the two schemas: for tokscos-work the usable archive hash is
`files.<p>.sha256`, whereas for tokscos-cli `platforms.<p>.sha256` is the hash of
the *unpacked exe* and `platforms.<p>.archive` is the archive.  Getting that wrong
yields a package that reviews cleanly but fails checksum validation on install.

For tokscos-cli the unpacked binary hash doubles as an identity check: if it does
not match, the artifact is not the build the metadata describes and the run fails.

Cost
----
Artifacts are downloaded only when the declared version actually changed, so the
daily run normally performs two small JSON fetches and nothing else.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import sys
import tempfile
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ElementTree
import zipfile
from dataclasses import dataclass
from itertools import zip_longest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
COS = "https://tokcos-1328134559.cos.ap-guangzhou.myqcloud.com"
UA = {"User-Agent": "greenflute-chocolatey-repo-bump"}
SHA256_RE = r"[0-9a-f]{64}"


@dataclass(frozen=True)
class Package:
    """One Chocolatey package plus the upstream layout it is fed from."""

    name: str
    nuspec: Path
    install_script: Path
    meta_url: str
    platform: str
    #: where the artifact list lives in latest.json ("files" or "platforms")
    meta_section: str
    #: metadata key holding the hash of the downloadable archive
    archive_hash_key: str
    #: metadata key holding a sha256 of the unpacked binary, if upstream has one
    binary_hash_key: str | None
    #: path of the main binary inside the archive, if binary_hash_key is set
    binary_member: str | None
    #: filename upstream publishes for this platform (may use {version})
    artifact_name: str


PACKAGES = (
    Package(
        name="tokcos-work",
        nuspec=REPO / "tokcos-work/tokcos-work.nuspec",
        install_script=REPO / "tokcos-work/tools/chocolateyinstall.ps1",
        meta_url=f"{COS}/tokcos-gui/release/latest.json",
        platform="win32-x64",
        meta_section="files",
        archive_hash_key="sha256",
        binary_hash_key=None,
        binary_member=None,
        artifact_name="Tokcos Work-{version}-x64.exe",
    ),
    Package(
        name="tokcos-cli",
        nuspec=REPO / "tokcos-cli/tokcos-cli.nuspec",
        install_script=REPO / "tokcos-cli/tools/chocolateyinstall.ps1",
        meta_url=f"{COS}/tokcos-cli/release/latest.json",
        platform="win32-x64",
        meta_section="platforms",
        archive_hash_key="archive",
        binary_hash_key="sha256",
        binary_member="win32-x64/tokcos-cli.exe",
        artifact_name="tokcos-cli-win32-x64.zip",
    ),
)


def log(message: str) -> None:
    print(message, flush=True)


def warn(message: str) -> None:
    print(f"::warning::{message}", flush=True)


def fail(message: str) -> None:
    print(f"::error::{message}", flush=True)
    raise SystemExit(1)


def set_output(name: str, value: str) -> None:
    path = os.environ.get("GITHUB_OUTPUT")
    if not path:
        return
    with open(path, "a", encoding="utf-8") as handle:
        handle.write(f"{name}={value}\n")


def fetch_json(url: str) -> dict:
    request = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def sha256_stream(stream) -> str:
    digest = hashlib.sha256()
    while chunk := stream.read(1 << 20):
        digest.update(chunk)
    return digest.hexdigest()


def download(url: str, dest: Path) -> tuple[str, int]:
    request = urllib.request.Request(url, headers=UA)
    digest = hashlib.sha256()
    size = 0
    with urllib.request.urlopen(request, timeout=900) as response, dest.open("wb") as handle:
        while chunk := response.read(1 << 20):
            handle.write(chunk)
            digest.update(chunk)
            size += len(chunk)
    return digest.hexdigest(), size


def sha256_zip_member(archive: Path, member: str) -> str:
    with zipfile.ZipFile(archive) as zf:
        try:
            stream = zf.open(member)
        except KeyError:
            fail(f"{archive.name}: member {member!r} not found")
        with stream:
            return sha256_stream(stream)


def version_tuple(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in re.findall(r"\d+", version))


def assert_not_a_downgrade(current: str, latest: str, what: str) -> None:
    """Refuse to move backwards if upstream appears to have rolled a release back.

    A downgrade is occasionally the right call after a retracted release, but it
    should be a deliberate edit rather than something a nightly job commits.
    """
    before, after = version_tuple(current), version_tuple(latest)
    if not before or not after:
        warn(f"{what}: cannot compare {current!r} with {latest!r} numerically")
        return
    for old, new in zip_longest(before, after, fillvalue=0):
        if old != new:
            if new < old:
                fail(
                    f"{what}: upstream reports {latest} which is older than the committed "
                    f"{current}; refusing to downgrade. Edit the package by hand if this is intended."
                )
            return


def substitute(text: str, pattern: str, build, expected: int, what: str) -> str:
    seen = {"n": 0}

    def replace(match: re.Match) -> str:
        seen["n"] += 1
        return build(match)

    updated = re.sub(pattern, replace, text)
    if seen["n"] != expected:
        fail(f"{what}: expected {expected} match(es), found {seen['n']}")
    return updated


def declared_nuspec_version(path: Path) -> str:
    return declared_nuspec_version_text(path.read_text(encoding="utf-8"), path)


def declared_nuspec_version_text(text: str, path: Path) -> str:
    """Parse nuspec text as XML and return the metadata version."""
    try:
        root = ElementTree.fromstring(text)
    except ElementTree.ParseError as error:
        fail(f"{path.name}: not valid XML: {error}")
    element = root.find(".//{*}version")
    if element is None or not element.text:
        fail(f"{path.name}: no <version> element found")
    return element.text


def bump(package: Package) -> str | None:
    meta = fetch_json(package.meta_url)
    latest = meta["version"]
    current = declared_nuspec_version(package.nuspec)

    if current == latest:
        log(f"{package.name}: already at {latest}")
        return None

    log(f"{package.name}: {current} -> {latest}")
    assert_not_a_downgrade(current, latest, package.name)

    info = meta[package.meta_section][package.platform]
    expected_name = package.artifact_name.format(version=latest)

    nuspec_text = package.nuspec.read_text(encoding="utf-8")
    script_text = package.install_script.read_text(encoding="utf-8")

    # The install script's URL must name the artifact upstream publishes for the
    # version currently declared -- that is what the file still holds.  Comparing
    # against `latest` here would reject every legitimate bump; comparing against
    # the version being replaced catches an upstream rename instead of shipping a 404.
    url_match = re.search(r"(?m)^\s*url\s*=\s*'([^']+)'", script_text)
    if url_match is None:
        fail(f"{package.name}: no url = '...' entry in {package.install_script.name}")
    declared_url = url_match.group(1)
    declared_name = urllib.parse.unquote(urllib.parse.urlsplit(declared_url).path.rsplit("/", 1)[-1])
    was_expected = package.artifact_name.format(version=current)
    if declared_name != was_expected:
        fail(
            f"{package.name}: install script downloads {declared_name!r} but version {current} "
            f"should be {was_expected!r}; update the script by hand"
        )

    # Derive the new URL from the script's own url so its quoting is preserved
    # exactly, and require it to name the artifact upstream publishes.
    new_url = declared_url.replace(current, latest)
    if urllib.parse.unquote(urllib.parse.urlsplit(new_url).path.rsplit("/", 1)[-1]) != expected_name:
        fail(
            f"{package.name}: new url {new_url!r} does not name {expected_name!r}; "
            "update the script by hand"
        )

    with tempfile.TemporaryDirectory() as workdir:
        archive = Path(workdir) / expected_name
        real, size = download(new_url, archive)

        if package.binary_hash_key is not None:
            inner = sha256_zip_member(archive, package.binary_member)
            claimed_inner = info[package.binary_hash_key]
            if inner != claimed_inner:
                fail(
                    f"{package.name}: unpacked {package.binary_member} hashes to {inner} but "
                    f"upstream declares {claimed_inner}; refusing to bump an unverified artifact"
                )
            log(f"  binary {inner} verified")

        claimed = info[package.archive_hash_key]
        if real != claimed:
            warn(
                f"{package.name}: upstream {package.archive_hash_key} {claimed} != artifact "
                f"{real}; using the artifact value"
            )
        if "size" in info and size != info["size"]:
            warn(f"{package.name}: upstream size {info['size']} != artifact {size}")
        log(f"  archive {real} ({size} bytes)")

    # --- nuspec ------------------------------------------------------------- #
    updated_nuspec = substitute(
        nuspec_text,
        r"(<version>)[^<]+(</version>)",
        lambda m: f"{m.group(1)}{latest}{m.group(2)}",
        1,
        f"{package.name} nuspec version",
    )
    if declared_nuspec_version_text(updated_nuspec, package.nuspec) != latest:
        fail(f"{package.name}: rewritten nuspec does not declare {latest}")

    # --- install script ----------------------------------------------------- #
    def fix_url(match: re.Match) -> str:
        value = match.group(2)
        if current not in value:
            fail(f"{package.name}: expected url to contain {current}: {value!r}")
        return f"{match.group(1)}'{value.replace(current, latest)}'"

    updated_script = substitute(
        script_text,
        r"(?m)^(\s*url\s*=\s*)'([^']*)'",
        fix_url,
        1,
        f"{package.name} install script url",
    )
    updated_script = substitute(
        updated_script,
        rf"(?m)^(\s*checksum\s*=\s*)'{SHA256_RE}'",
        lambda m: f"{m.group(1)}'{real}'",
        1,
        f"{package.name} install script checksum",
    )

    # Assert against full delimiters rather than bare version substrings: "0.5.9"
    # occurs inside "0.5.90", so a substring test would reject a legitimate prefix
    # bump with a confusing "old version still present" error.
    if f"<version>{current}</version>" in updated_nuspec:
        fail(f"{package.name}: old version {current} still present in the nuspec")
    if declared_url in updated_script:
        fail(f"{package.name}: the old download url is still present in the install script")
    if updated_script.count(real) != 1:
        fail(f"{package.name}: expected exactly one occurrence of checksum {real}")
    final_match = re.search(r"(?m)^\s*url\s*=\s*'([^']+)'", updated_script)
    if final_match is None:
        fail(f"{package.name}: rewritten install script has no url")
    if final_match.group(1) != new_url:
        fail(
            f"{package.name}: rewritten install script downloads {final_match.group(1)!r}, "
            f"expected {new_url!r}"
        )

    package.nuspec.write_text(updated_nuspec, encoding="utf-8")
    package.install_script.write_text(updated_script, encoding="utf-8")
    log(f"  {package.nuspec.relative_to(REPO)} and {package.install_script.relative_to(REPO)} rewritten")
    return latest


def main() -> int:
    versions = {package.name: bump(package) for package in PACKAGES}

    for package in PACKAGES:
        key = package.name.replace("tokcos-", "")
        version = versions[package.name]
        set_output(f"{key}_changed", "true" if version else "false")
        set_output(f"{key}_version", version or "")

    set_output("changed", "true" if any(versions.values()) else "false")
    if not any(versions.values()):
        log("All Tokcos Chocolatey packages are already up to date.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
