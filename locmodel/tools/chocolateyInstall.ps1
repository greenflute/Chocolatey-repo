$ErrorActionPreference = 'Stop'

if (-not [Environment]::Is64BitOperatingSystem) {
  throw 'LocModel is only available for 64-bit Windows.'
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://locmodel.com/LocModel_3.5.1_x64-setup.exe'
  silentArgs     = '/S'
  validExitCodes = @(0, 3010, 1641)
  softwareName   = 'LocModel*'
}

Install-ChocolateyPackage @packageArgs
