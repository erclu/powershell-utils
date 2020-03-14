# Export Windows package manager programs
function Export-ScoopPackages {
  function Read-RawLine {
    Param(
      [String]
      $line
    )
    $MatchPattern = "^(?<Name>.+) \(v\:(?<Version>.*?)\) (?<Global>\*global\* ){0,1}\[(?<Bucket>.*?)\]$"

    $MatchFound = $line -match $MatchPattern
    if (-not $MatchFound) {
      Write-Error "line was not parsed correctly: $line"
    }

    return [PSCustomObject]@{
      Name     = $Matches["Name"]
      Version  = $Matches["Version"]
      IsGlobal = if ($Matches["Global"]) {
        $true
      }
      else {
        $false
      }
      Bucket   = $Matches["Bucket"]
    }
  }

  $parsed = scoop.ps1 export | ForEach-Object { Read-RawLine $_ }

  $programs = $parsed | Select-Object -ExcludeProperty Bucket
  $buckets = $parsed | Select-Object -Unique -ExpandProperty Bucket

  [ordered]@{
    When        = (Get-Date -Format "o")
    UsedBuckets = $buckets
    Programs    = $programs
  } |
    ConvertTo-Json
}

## npm globals
# "npm install" takes multiple arguments separated by space
function Export-NpmGlobalPackages {
  $rawList = npm.cmd list --global --depth=0 --parseable

  $baseFolder, $packages = $rawList
  $basePath = Join-Path $baseFolder "node_modules\"

  ($packages | ForEach-Object { $_ -replace [regex]::Escape($basePath) -replace "\\", "/" }) -join " "
}

## python globals.
# "pip install" can parse a file
function Export-PipxGlobalPackages {
  # TODO finish implementing
  pipx.exe list | Where-Object { $_ -match "package (.*), Python" }
}

function Export-EnvironmentVariables {
  $user = [Environment]::GetEnvironmentVariables("User")
  $machine = [Environment]::GetEnvironmentVariables("Machine")

  [ordered]@{
    when    = (Get-Date -Format "o")
    user    = $user
    machine = $machine
  } |
    ConvertTo-Json
} # > EnvironmentVariables.json

function Get-SomeInstalledPrograms {
  Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Sort-Object DisplayName |
    Format-Table -AutoSize
}

# TODO check if i need to backup something else
