$ErrorActionPreference = 'Stop'

if (-not [Environment]::Is64BitOperatingSystem) {
  throw 'Tokcos Work is only available for 64-bit Windows.'
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://tokcos-1328134559.cos.ap-guangzhou.myqcloud.com/tokcos-gui/release/1.2.4/Tokcos%20Work-1.2.4-x64.exe'
  checksum       = 'c2cd4795e729c487e5faba435141a99dd312721090cd2cd4e307d30b53ac40fb'
  checksumType   = 'sha256'
  silentArgs     = '/S'
  validExitCodes = @(0)
  softwareName   = 'Tokcos Work*'
}

Install-ChocolateyPackage @packageArgs
