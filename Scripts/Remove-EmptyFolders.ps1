# TODO use supportshouldprocess
[CmdletBinding()]
param (
  [System.IO.DirectoryInfo]
  $Path = "."
)

Get-ChildItem -Recurse -Directory $Path |
  Where-Object { -not $_.GetFiles("*", "AllDirectories") } |
  Remove-Item -Recurse
