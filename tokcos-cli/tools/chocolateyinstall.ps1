$ErrorActionPreference = 'Stop'

if (-not [Environment]::Is64BitOperatingSystem) {
  throw 'Tokcos CLI is only available for 64-bit Windows.'
}

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url            = 'https://tokcos-1328134559.cos.ap-guangzhou.myqcloud.com/tokcos-cli/release/2.0.7/tokcos-cli-win32-x64.zip'
  checksum       = 'd7a137e30abf7b7178d1cac6983894770173bfdfc463120210a9f7a24e4bf238'
  checksumType   = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

$runtimeDir = Join-Path $toolsDir 'win32-x64'
$cliPath = Join-Path $runtimeDir 'tokcos-cli.exe'

Get-ChildItem -Path $runtimeDir -Filter '*.exe' -Recurse |
  Where-Object { $_.FullName -ne $cliPath } |
  ForEach-Object {
    New-Item -ItemType File -Path "$($_.FullName).ignore" -Force | Out-Null
  }
