$ErrorActionPreference = 'Stop'

if (-not [Environment]::Is64BitOperatingSystem) {
  throw 'Tokcos Work is only available for 64-bit Windows.'
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://tokcos-1328134559.cos.ap-guangzhou.myqcloud.com/tokcos-gui/release/1.5.1/Tokcos%20Work-1.5.1-x64.exe'
  checksum       = '24ee3e25bbbd62cbe33f90709fe9489dd64532beea8ff2659af7e3a28998f9bd'
  checksumType   = 'sha256'
  silentArgs     = '/S'
  validExitCodes = @(0)
  softwareName   = 'Tokcos Work*'
}

Install-ChocolateyPackage @packageArgs
