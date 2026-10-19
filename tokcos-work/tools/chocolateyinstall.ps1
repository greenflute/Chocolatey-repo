$ErrorActionPreference = 'Stop'

if (-not [Environment]::Is64BitOperatingSystem) {
  throw 'Tokcos Work is only available for 64-bit Windows.'
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://tokcos-1328134559.cos.ap-guangzhou.myqcloud.com/tokcos-gui/release/1.3.0/Tokcos%20Work-1.3.0-x64.exe'
  checksum       = '1d06e945db232ed3796abf2b0c9b2fd44ae1506d2552f3c6b3dbebc55f8f2003'
  checksumType   = 'sha256'
  silentArgs     = '/S'
  validExitCodes = @(0)
  softwareName   = 'Tokcos Work*'
}

Install-ChocolateyPackage @packageArgs
