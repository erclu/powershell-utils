# Load SuT
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

Describe "Rebase-FeaturesOnTrunk" {
  ## Arrange

  # create folder
  [System.IO.DirectoryInfo] $repo = New-Item -ItemType Directory "TestDrive:/root folder"

  New-Item -ItemType Directory @(
    "$repo/folder1"
  )

  # create files with some content
  Set-Content -LiteralPath "$repo/file1.ext" -Value "content1"
  Set-Content -LiteralPath "$repo/folder1/file2.ext" -Value "content2"

  # initialize repo
  git.exe init $repo

  git.exe --git-dir "$repo/.git" add "$repo/file1.ext", "$repo/folder1/file2.ext"
  git.exe --git-dir "$repo/.git" commit -m "init"

  ## Act

  ## Assert

  It "is not implemented" {
    throw "NOT IMPLEMENTED"
  }
}
