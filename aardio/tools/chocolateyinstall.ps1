$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url            = 'https://d.aardio.com/ide/aardio.7z'
  checksum       = 'fa36ecf68f5bf3c5d461e4e795c0c39c1e5f7bf5b604bc9e7eab8e38382b3d15'
  checksumType   = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

$aardioPath = Join-Path $toolsDir 'aardio.exe'

Get-ChildItem -Path $toolsDir -Filter '*.exe' -Recurse |
  Where-Object { $_.FullName -ne $aardioPath } |
  ForEach-Object {
    New-Item -ItemType File -Path "$($_.FullName).ignore" -Force | Out-Null
  }
