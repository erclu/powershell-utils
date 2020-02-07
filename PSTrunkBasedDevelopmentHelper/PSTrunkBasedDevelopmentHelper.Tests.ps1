$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

Describe "Rebase-FeaturesOnTrunk" {
  ## Arrange
  Import-Module -Force $here/$sut

  # create repo folder
  [System.IO.DirectoryInfo] $repo = New-Item -ItemType Directory "TestDrive:/root folder"

  # create files with some content
  $files = @{
    Paths    = @(
      "$repo/file1.ext"
      "$repo/folder1/file2.ext"
    )
    Contents = @(
      "content1"
      "content2"
    )
  }

  New-Item -Force -ItemType File -Path $files.Paths
  Set-Content -LiteralPath $files.Paths -Value $files.Contents

  # initialize repo
  git.exe init $repo

  git.exe --git-dir "$repo/.git" add $files.Paths
  git.exe --git-dir "$repo/.git" commit -m "init"

  ## Act

  ## Assert

  It "is not implemented" {
    throw "NOT IMPLEMENTED"
  }

  # Cleanup
  Remove-Item -Recurse $repo
}
