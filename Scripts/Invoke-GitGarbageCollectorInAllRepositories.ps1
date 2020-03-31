[CmdletBinding()]
param (
  # Folder to search for dirty repositories
  [System.IO.DirectoryInfo]
  $RootFolder = $env:PROJECTS_FOLDER,
  [switch]
  $Quiet
)

Write-Output "Searching for repositories in $RootFolder..."

$repos = Get-ChildItem -Verbose -Directory -Force -Recurse $RootFolder |
  Where-Object FullName -NotMatch "node_modules" |
  Where-Object FullName -NotMatch "vendor" |
  Where-Object FullName -NotMatch "Library" |
  Where-Object FullName -Match ".git$" |
  ForEach-Object {
    Write-Verbose "scanning $($_.FullName)"
    $_
  }

Write-Output "Found $($repos.Length) repos."

$repos |
  ForEach-Object {
    $gitDir = $_
    $workTree = Split-Path -Path $_ -Parent

    Write-Output "running aggressive garbage collection in $workTree"

    if ($Quiet) {
      git --git-dir $gitDir gc --aggressive | Out-Null
    }
    else {
      git --git-dir $gitDir gc --aggressive
    }

    if ($LASTEXITCODE) {
      Write-Error "Something wrong in $workTree"
    }
  }

Write-Output "Done."
