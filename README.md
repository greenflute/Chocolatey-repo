# Chocolatey repository

Personal Chocolatey repository for Tokcos and other useful Windows software.

## Build a package

```powershell
cd <package-directory>
choco pack
```

## Local test

```powershell
choco install <package-id> --source . --yes
```

Tokcos package IDs:

```text
tokcos-cli
tokcos-work
```

Other package IDs:

```text
aardio
moonbit
```

The official MoonBit VS Code extension currently looks for its toolchain under
`%MOON_HOME%\bin` (default: `%USERPROFILE%\.moon\bin`) instead of using commands
installed through Chocolatey, so it does not automatically discover this installation.
For VS Code use, let the official extension manage its own toolchain for now.
