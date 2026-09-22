$ErrorActionPreference = 'Stop'

if (-not [Environment]::Is64BitOperatingSystem) {
  throw 'Tokcos Work is only available for 64-bit Windows.'
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://tokcos-1328134559.cos.ap-guangzhou.myqcloud.com/tokcos-gui/release/1.2.2/Tokcos%20Work-1.2.2-x64.exe'
  checksum       = '0741343806de3eac3a10584b61935234b1d9e60c9d79e4744be150012c7e5af8'
  checksumType   = 'sha256'
  silentArgs     = '/S'
  validExitCodes = @(0)
  softwareName   = 'Tokcos Work*'
}

Install-ChocolateyPackage @packageArgs
