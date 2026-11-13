$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url            = 'https://d.aardio.com/ide/aardio.7z'
  checksum       = '3d65059f7b20244eb5f91464724a00759d7c46901c7ea4ae90f3e27ed8f65dde'
  checksumType   = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

$aardioPath = Join-Path $toolsDir 'aardio.exe'

Get-ChildItem -Path $toolsDir -Filter '*.exe' -Recurse |
  Where-Object { $_.FullName -ne $aardioPath } |
  ForEach-Object {
    New-Item -ItemType File -Path "$($_.FullName).ignore" -Force | Out-Null
  }
