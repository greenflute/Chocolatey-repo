$ErrorActionPreference = 'Stop'

if (-not [Environment]::Is64BitOperatingSystem) {
  throw 'Tokcos Work is only available for 64-bit Windows.'
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://tokcos-1328134559.cos.ap-guangzhou.myqcloud.com/tokcos-gui/release/1.2.7/Tokcos%20Work-1.2.7-x64.exe'
  checksum       = '17910d31d95b32f710aa77e5c65ce946304bc6c3078e0f417f41598664b23e85'
  checksumType   = 'sha256'
  silentArgs     = '/S'
  validExitCodes = @(0)
  softwareName   = 'Tokcos Work*'
}

Install-ChocolateyPackage @packageArgs
