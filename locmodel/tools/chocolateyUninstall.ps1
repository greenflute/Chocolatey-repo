$ErrorActionPreference = 'Stop'

$entries = Get-UninstallRegistryKey -SoftwareName 'LocModel*'
foreach ($entry in $entries) {
  $command = $entry.UninstallString
  if ([string]::IsNullOrWhiteSpace($command)) {
    continue
  }

  if ($command -match '^\s*"([^"]+)"\s*(.*)$') {
    $uninstaller = $Matches[1]
    $arguments = $Matches[2]
  } elseif ($command -match '^\s*(\S+)\s*(.*)$') {
    $uninstaller = $Matches[1]
    $arguments = $Matches[2]
  } else {
    throw "Could not parse LocModel uninstall command: $command"
  }

  if ($arguments -notmatch '(?i)(^|\s)/S(\s|$)') {
    $arguments = "$arguments /S".Trim()
  }

  $process = Start-Process -FilePath $uninstaller -ArgumentList $arguments -Wait -PassThru
  if ($process.ExitCode -notin @(0, 1605, 1614, 1641, 3010)) {
    throw "LocModel uninstall failed with exit code $($process.ExitCode)."
  }
}
