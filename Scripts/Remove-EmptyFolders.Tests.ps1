# Load SuT
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

Describe "Remove-EmptyFolders" {
  # Arrange
  $testFolder = "$TestDrive/root folder"
  New-Item -ItemType Directory $testFolder

  New-Item -Force -ItemType File @(
    "$testFolder/ShouldNotBeDeleted1/file1.ext"
    "$testFolder/ShouldNotBeDeleted2/ShouldNotBeDeleted3/file2.ext"
  )

  New-Item -ItemType Directory @(
    "$testFolder/ShouldBeDeleted1"
    "$testFolder/ShouldBeDeleted2/ShouldBeDeleted3"
    "$testFolder/ShouldNotBeDeleted2/ShouldBeDeleted4"
  )

  # Act
  . "$here/$sut" -Confirm:$false $testFolder

  ## Assert
  It "does not remove non-empty folders" {

    "$testFolder/ShouldNotBeDeleted1/",
    "$testFolder/ShouldNotBeDeleted2/",
    "$testFolder/ShouldNotBeDeleted2/ShouldNotBeDeleted3" |
      ForEach-Object { Test-Path $_ | Should -Be $true }
  }

  It "removes empty folders" {

    "$testFolder/ShouldBeDeleted1",
    "$testFolder/ShouldBeDeleted2",
    "$testFolder/ShouldBeDeleted2/ShouldBeDeleted3",
    "$testFolder/ShouldNotBeDeleted2/ShouldBeDeleted4" |
      ForEach-Object { Test-Path $_ | Should -Be $false }
  }

  # Cleanup
  Remove-Item -Recurse $testFolder
}
