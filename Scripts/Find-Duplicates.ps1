[CmdletBinding()]
param (
  [Parameter()]
  [System.IO.DirectoryInfo[]]
  $Paths = (Get-Location)
)

# TODO implement me
throw "NOT IMPLEMENTED"

$files = Get-ChildItem -LiteralPath $Paths

$files | ForEach-Object {
  $size = $_.Length

}
