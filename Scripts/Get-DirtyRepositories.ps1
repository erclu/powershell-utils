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

function Test-HasUncommittedChanges {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.IO.DirectoryInfo]
    $path
  )

  return $null -ne (git -C $path status -s)
}

function Test-HasNoRemote {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.IO.DirectoryInfo]
    $path
  )

  return $null -eq (git -C $path remote)
}

function Test-HasUnpushedCommits {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.IO.DirectoryInfo]
    $path
  )

  return $null -ne (git -C $path log --branches --not --remotes --oneline)
}

function Test-HasForgottenStashes {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.IO.DirectoryInfo]
    $path
  )

  return $null -ne (git -C $path stash list)
}

function Test-HasIgnoredFilesAndFolder {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [System.IO.DirectoryInfo]
    $path
  )

  return ( git -C $path status -s --ignored ) |
    Select-String -Pattern "^!!" |
    Measure-Object |
    Select-Object -ExpandProperty Count
}

Write-Output "Searching for repositories in $RootFolder ..."

$repos = Get-ChildItem -Verbose -Directory -Force -Recurse $RootFolder |
  Where-Object FullName -NotMatch "node_modules" |
  Where-Object FullName -NotMatch "vendor" |
  Where-Object FullName -NotMatch "Library" |
  Where-Object FullName -Match ".git$" |
  ForEach-Object {
    Write-Verbose "scanning $($_.FullName)"
    $_
  }

Write-Output "found $($repos.Length) repos; checking status..."

$repos |
  ForEach-Object {
    $workTree = Split-Path -Path $_ -Parent

    $uncommittedChanges = Test-HasUncommittedChanges $workTree
    $hasNoRemote = Test-HasNoRemote $workTree
    $unpushedCommits = Test-HasUnpushedCommits $workTree
    $forgottenStashes = Test-HasForgottenStashes $workTree
    $ignoredFilesAndFolders = Test-HasIgnoredFilesAndFolder $workTree

    [pscustomobject]@{
      PSTypename         = "GitRepo"
      Repo               = $workTree
      AllGood            = -not ($uncommittedChanges -or $hasNoRemote -or $unpushedCommits -or $forgottenStashes )
      UncommittedChanges = $uncommittedChanges
      HasNoRemote        = $hasNoRemote
      CommitsToPush      = $unpushedCommits
      StashesToClear     = $forgottenStashes
      # AllGood does not count these
      Ignored            = $ignoredFilesAndFolders
    }
  }
