[CmdletBinding()]
param (
  # Folder to search for dirty repositories
  [System.IO.DirectoryInfo]
  $RootFolder = $env:PROJECTS_FOLDER,
  [switch]
  $Verbose
)

Write-Output "Searching for repositories in $RootFolder..."

$repos = Get-ChildItem -Directory -Force -Recurse $RootFolder -Include ".git" |
  Where-Object FullName -NotMatch "node_modules"

Write-Output "Found $($repos.Length) repos."

$repos |
  ForEach-Object {
    $gitDir = $_
    $workTree = Split-Path -Path $_ -Parent

    Write-Output "running aggressive garbage collection in $workTree"

    if ($Verbose) {
      git --git-dir $gitDir gc --aggressive
    }
    else {
      git --git-dir $gitDir gc --aggressive | Out-Null
    }

    if ($LASTEXITCODE) {
      Write-Error "Something wrong in $workTree"
    }
  }

Write-Output "Done."
