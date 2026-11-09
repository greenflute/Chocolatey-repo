$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url            = 'https://d.aardio.com/ide/aardio.7z'
  checksum       = '933aa4685d4294970052334e5b7cb579b8bbca443b2750057a0cb9ead9dd037c'
  checksumType   = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

$aardioPath = Join-Path $toolsDir 'aardio.exe'

Get-ChildItem -Path $toolsDir -Filter '*.exe' -Recurse |
  Where-Object { $_.FullName -ne $aardioPath } |
  ForEach-Object {
    New-Item -ItemType File -Path "$($_.FullName).ignore" -Force | Out-Null
  }
