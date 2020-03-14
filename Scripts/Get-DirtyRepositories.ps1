[CmdletBinding()]
param (
  # Folder to search for dirty repositories
  [System.IO.DirectoryInfo]
  $RootFolder = $env:PROJECTS_FOLDER,
  [string]
  $SaveToVariable
)

# TODO export type data?
# Update-TypeData ...

$forEachArguments = @{
  OutVariable = if ($SaveToVariable) {
    "OutVariable"
  }
  else {
    $null
  }
}

function Test-HasDirtyIndex {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.IO.DirectoryInfo]
    $gitDir
  )

  return $null -ne (git.exe --git-dir $gitDir --work-tree $workTree status -s)
}

function Test-HasUnpushedCommits {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.IO.DirectoryInfo]
    $gitDir
  )

  return $null -ne (git.exe --git-dir $gitDir --work-tree $workTree log --branches --not --remotes --oneline)
}

function Test-HasForgottenStashes {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.IO.DirectoryInfo]
    $gitDir
  )

  return $null -ne (git.exe --git-dir $gitDir stash list)
}
Write-Output "Searching for repositories in $RootFolder ..."

$repos = Get-ChildItem -Directory -Force -Recurse $RootFolder -Include ".git" -Exclude "node_modules"

Write-Output "found $($repos.Length) repos; checking status..."

$repos |
  ForEach-Object {
    $gitDir = $_
    $workTree = Split-Path -Path $_ -Parent

    [pscustomobject]@{
      PSTypename      = "GitRepo"
      Repo            = $workTree
      AllGood         = -not ($dirtyIndex -or $unpushedCommits -or $forgottenStashes)
      ChangesToCommit = Test-HasDirtyIndex $gitDir
      CommitsToPush   = Test-HasUnpushedCommits $gitDir
      StashesToClear  = Test-HasForgottenStashes $gitDir
    }
  } @forEachArguments

if ($SaveToVariable) {
  Write-Verbose "setting variable $SaveToVariable in parent scope"
  Set-Variable -Scope 1 -Name $SaveToVariable -Value $OutVariable
}
