$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url            = 'https://d.aardio.com/ide/aardio.7z'
  checksum       = '3daf193f46aff5faf651ca126f2776731352755901b70826b76ab93a1f38ee87'
  checksumType   = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

$aardioPath = Join-Path $toolsDir 'aardio.exe'

Get-ChildItem -Path $toolsDir -Filter '*.exe' -Recurse |
  Where-Object { $_.FullName -ne $aardioPath } |
  ForEach-Object {
    New-Item -ItemType File -Path "$($_.FullName).ignore" -Force | Out-Null
  }
