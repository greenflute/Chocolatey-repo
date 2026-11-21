$ErrorActionPreference = 'Stop'

if (-not [Environment]::Is64BitOperatingSystem) {
  throw 'Zditor is only available for 64-bit Windows.'
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'msi'
  url            = 'https://download.zditor.com/zditor-v2.0.9/zditor_2.0.9_x64_en-US.msi'
  silentArgs     = '/qn /norestart'
  validExitCodes = @(0, 3010, 1641)
  softwareName   = 'Zditor*'
}

Install-ChocolateyPackage @packageArgs
