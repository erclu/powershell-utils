#Requires -Module ClipboardText
[CmdletBinding()]
param (
  # Root folder of the module
  [Parameter(Mandatory)]
  [ValidateScript( { Test-Path -LiteralPath $_ })]
  [System.IO.DirectoryInfo]
  $ModuleFolder,
  # Optional files to exclude
  [System.IO.FileInfo[]]
  $Exclude
)

# TODO manage single-file module
$Public = Join-Path $ModuleFolder "Public"
if (-not (Test-Path $Public)) {
  throw "No public folder found in module"
}

Get-ChildItem $ModuleFolder -Recurse -Exclude "*Config.ps1", $Exclude -Include "*.ps1" |
  Where-Object FullName -notmatch 'Scripts' |
  ForEach-Object {
    $name = $_.Name -replace "\.ps1"
    $functionName = (Get-Content $_ | Select-Object -First 1) -replace "function " -replace " {"
    if ($functionName -ne $name) {
      Write-Error -Message "File and Function have different names `n$_" -TargetObject $_
    }
  }

Get-ChildItem $ModuleFolder -Recurse -Exclude "*Config.ps1", $Exclude -Include "*.ps1" |
  ForEach-Object { "`"$($_.Name -replace ".ps1")`"" } |
  Set-ClipboardText
