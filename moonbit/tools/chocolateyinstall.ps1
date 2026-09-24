$ErrorActionPreference = 'Stop'

if (-not [Environment]::Is64BitOperatingSystem) {
  throw 'MoonBit is only available for 64-bit Windows.'
}

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$toolchainArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url            = 'https://cli.moonbitlang.com/binaries/0.10.14%2B7d59c7ec9/moonbit-windows-x86_64.zip'
  checksum       = 'faae225a8287d0ce69e44b5b3f754af988e97f4446056d8f32ceb3ddb998fce7'
  checksumType   = 'sha256'
}

Install-ChocolateyZipPackage @toolchainArgs

$coreArgs = @{
  packageName    = "$env:ChocolateyPackageName-core"
  unzipLocation = Join-Path $toolsDir 'lib'
  url            = 'https://cli.moonbitlang.com/cores/core-0.10.14%2B7d59c7ec9.zip'
  checksum       = '63e5b99991ac8fd49556b1e17bdcbdc662d797000250dd11ef090f38a2175e84'
  checksumType   = 'sha256'
}

Install-ChocolateyZipPackage @coreArgs

$binDir = Join-Path $toolsDir 'bin'
$moonExe = Join-Path $binDir 'moon.exe'
$moonxExe = Join-Path $binDir 'moonx.exe'

try {
  New-Item -ItemType HardLink -Path $moonxExe -Target $moonExe -ErrorAction Stop | Out-Null
} catch {
  Copy-Item -Path $moonExe -Destination $moonxExe -Force
}

$previousToolchainRoot = $env:MOON_TOOLCHAIN_ROOT
$previousPath = $env:PATH

try {
  $env:MOON_TOOLCHAIN_ROOT = $toolsDir
  $env:PATH = "$binDir;$env:PATH"
  $coreDir = Join-Path $toolsDir 'lib\core'

  & $moonExe -C $coreDir bundle --warn-list -a --all
  if ($LASTEXITCODE -ne 0) {
    throw "MoonBit core bundling failed with exit code $LASTEXITCODE."
  }

  & $moonExe -C $coreDir bundle --warn-list -a --target wasm-gc --quiet
  if ($LASTEXITCODE -ne 0) {
    throw "MoonBit wasm-gc core bundling failed with exit code $LASTEXITCODE."
  }
} finally {
  $env:MOON_TOOLCHAIN_ROOT = $previousToolchainRoot
  $env:PATH = $previousPath
}

# Chocolatey creates shims for top-level toolchain commands only. Internal helper
# executables must continue to be discovered relative to the toolchain root.
Get-ChildItem -Path $toolsDir -Filter '*.exe' -Recurse |
  Where-Object { $_.DirectoryName -ne $binDir } |
  ForEach-Object {
    New-Item -ItemType File -Path "$($_.FullName).ignore" -Force | Out-Null
  }
