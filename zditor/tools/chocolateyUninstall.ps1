$ErrorActionPreference = 'Stop'

$entries = Get-UninstallRegistryKey -SoftwareName 'Zditor*'
foreach ($entry in $entries) {
  if ($entry.PSChildName -match '^\{[0-9A-Fa-f-]{36}\}$') {
    $process = Start-Process -FilePath 'msiexec.exe' `
      -ArgumentList @('/x', $entry.PSChildName, '/qn', '/norestart') `
      -Wait -PassThru

    if ($process.ExitCode -notin @(0, 1605, 1614, 1641, 3010)) {
      throw "Zditor MSI uninstall failed with exit code $($process.ExitCode)."
    }
  }
}
