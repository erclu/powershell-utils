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
    $workTree = Split-Path -Path $_ -Parent

    Write-Output "running aggressive garbage collection in $workTree"

    $output = git -C $workTree gc --aggressive

    if (-not $Quiet) {
      Write-Output $output
    }

    if ($LASTEXITCODE) {
      Write-Error "Something wrong in $workTree"
    }
  }

Write-Output "Done."
