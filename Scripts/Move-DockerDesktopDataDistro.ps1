[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param (
  # Path of tar file
  [Parameter()]
  [string]
  $TarFileName = "W:\docker-desktop-data.tar",
  # Path where the new distro is imported
  [string]
  [string]
  $WslDistroDestination = "W:\docker-desktop-data\"
)

Write-Output "shutting down WSL"
wsl --shutdown

Write-Output "---"
wsl -l -v
Write-Output "---"

if ($PSCmdlet.ShouldProcess($TarFileName, "export wsl distro")) {
  wsl --export docker-desktop-data $TarFileName
}
else {
  throw "cannot continue"
}

if ($PSCmdlet.ShouldProcess("docker-desktop-data", "unregister wsl distro")) {
  wsl --unregister docker-desktop-data
}
else {
  throw "cannot continue"
}

if ($PSCmdlet.ShouldProcess($WslDistroDestination, "import wsl distro")) {
  wsl --import docker-desktop-data $WslDistroDestination $TarFileName --version 2
}
else {
  throw "cannot continue"
}
