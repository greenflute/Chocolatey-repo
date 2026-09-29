$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url            = 'https://d.aardio.com/ide/aardio.7z'
  checksum       = '205055abe01a2cd2a3b458a93b63beb32ad482016f93e68a35abfa7a31212606'
  checksumType   = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

$aardioPath = Join-Path $toolsDir 'aardio.exe'

Get-ChildItem -Path $toolsDir -Filter '*.exe' -Recurse |
  Where-Object { $_.FullName -ne $aardioPath } |
  ForEach-Object {
    New-Item -ItemType File -Path "$($_.FullName).ignore" -Force | Out-Null
  }
