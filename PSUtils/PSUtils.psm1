########################################################################################################################
####################################### Scoop utils
########################################################################################################################

function Get-ScoopSize {
  $cache = Get-ChildItem -Recurse $env:SCOOP/cache |
    Measure-Object -Sum Length |
    Select-Object -ExpandProperty Sum

  $persisted = Get-ChildItem -Recurse $env:SCOOP/persist |
    Measure-Object -Sum Length |
    Select-Object -ExpandProperty Sum

  $installed = Get-ChildItem -Recurse $env:SCOOP/apps |
    Measure-Object -Sum Length |
    Select-Object -ExpandProperty Sum


  [PSCustomObject]@{
    "cache size (MB)"          = [math]::Round($cache / 1MB, 2)
    "persisted data size (MB)" = [math]::Round($persisted / 1MB, 2)
    "installed apps size (GB)" = [math]::Round($installed / 1GB, 2)
  }
}

function Update-ScoopAndCleanAfter {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param ()

  $telegram = "telegram"

  scoop update
  $out = scoop status 6>&1
  $out
  if ($out -match $telegram) {
    Write-Output "stopping telegram..."
    Get-Process $telegram | Stop-Process
  }

  if ($PSCmdlet.ShouldProcess("Update apps")) {
    scoop update *
  }

  Write-Output "Running scoop cleanup..."
  scoop cleanup *

  Write-Output "Clearing cache..."
  scoop cache show
  scoop cache rm *

  if ($out -match $telegram) {
    Write-Output "starting telegram..."
    & $telegram
  }
}

########################################################################################################################
####################################### JSCPD
########################################################################################################################

function Invoke-CopyPasteDetectorDefaultConfig {
  [CmdletBinding()]
  param (
    # path
    [Parameter(Mandatory = $true)]
    [System.IO.DirectoryInfo]
    $Folder
  )

  jscpd --config "$($env:PROJECTS_FOLDER)/_CONFIGS/.jscpd.json" $Folder
}

########################################################################################################################
####################################### File utils
########################################################################################################################

function Test-ContainsBOM {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [System.IO.FileInfo]
    $file
  )

  process {
    $contents = New-Object byte[] 3
    $stream = [System.IO.File]::OpenRead($file.FullName)
    $stream.Read($contents, 0, 3) | Out-Null
    $stream.Close()

    return $contents[0] -eq 0xEF -and $contents[1] -eq 0xBB -and $contents[2] -eq 0xBF
  }
}

function Test-HasCrlfEndings {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [System.IO.FileInfo]
    $file
  )

  process {
    (Get-Content -Raw -LiteralPath $file.FullName) -match "`r`n"
  }
}

function Test-BomHereRecursive {

  Get-ChildItem -File -Recurse |
    Where-Object FullName -NotMatch ".zip" |
    Where-Object FullName -NotMatch ".git" |
    Where-Object FullName -NotMatch ".mypy_cache" |
    Where-Object FullName -NotMatch "node_modules" |
    Where-Object FullName -NotMatch "vendor" |
    Where-Object { -not (Test-ContainsBOM $_) } |
    Select-Object FullName
}
function Find-Duplicates {
  [CmdletBinding()]
  param (
    [Parameter()]
    [String[]]
    $Paths = "."
  )
  python 'D:/Projects/__libraries-wheels-etc/find_duplicates.py' $Paths
}

function New-TemporaryDirectory {
  $parent = [System.IO.Path]::GetTempPath()
  [string] $name = [System.Guid]::NewGuid()
  New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function New-FastTemporaryDirectory {
  [string] $name = [System.Guid]::NewGuid()
  New-Item -ItemType Directory -Path ("C:/TEMP-$name")
}

########################################################################################################################
####################################### Hardlinks utils
########################################################################################################################

function New-HardLink {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  Param(
    [parameter(position = 0)] [String] $Name,
    [parameter(position = 1)] [Object] $Value
  )

  if ($PSCmdlet.ShouldProcess("Create new HardLink")) {
    New-Item -ItemType HardLink -Name $Name -Value $Value
  }
}

function Find-HardLinks {
  Get-ChildItem . -Recurse -Force |
    Where-Object { $_.LinkType } |
    Select-Object FullName, LinkType, Target
}

########################################################################################################################
####################################### Misc
########################################################################################################################

function Invoke-SshCopyId {
  Param(
    [parameter(Mandatory, Position = 1)]
    [String]
    $Destination
  )

  Get-Content "~/.ssh/id_rsa.pub" | ssh $Destination "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
}


function Add-ModuleShim {
  [CmdletBinding()]
  param (
    [System.IO.DirectoryInfo]
    $ModuleFolder
  )

  $ModuleName = $ModuleFolder.Name

  $ShimPath = Join-Path "$HOME/Documents/PowerShell/Modules/" $ModuleName

  New-Item -ItemType Junction -Path $ShimPath -Value $ModuleFolder -Confirm
}

function Get-OldVsCodeExtensions {
  [CmdletBinding()]
  param (
    # [switch]
    # $Aggro
  )

  $VSCODE_EXTENSIONS_DIR = "C:/Tools/scoop/apps/vscode-portable/current/data/extensions"

  $SEMVER_REGEX = "(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-((?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?"
  $SPLITTER_REGEX = "^(?<name>.*?)-(?<version>$SEMVER_REGEX)$"

  # if (-not $Aggro) {
  # $DATETIME_CUTOFF = (Get-Date).AddDays(-7)
  # }
  # else {
  # $DATETIME_CUTOFF = Get-Date
  # }

  $parsedExtensionFolders = @(
    Get-ChildItem -Directory -Path $VSCODE_EXTENSIONS_DIR |
      Sort-Object -Descending CreationTime |
      ForEach-Object {
        $name = $_.Name

        if (-not ($name -match $SPLITTER_REGEX)) {
          Write-Error "this name is not correctly matched: $name"
        }

        [pscustomobject]@{
          Name      = $Matches.name
          Version   = $Matches.version
          Directory = $_
        }
      }
  )

  # $VSCODE_INSTALLED_EXTENSIONS = @(code --list-extensions) |
  #   ForEach-Object {
  #     [PSCustomObject]@{
  #       Name = $_
  #     }
  #   }
  # $uniqueExtensionFoldersFound = @($parsedExtensionFolders | Sort-Object Name -Unique)

  # Compare-Object -PassThru $VSCODE_INSTALLED_EXTENSIONS $uniqueExtensionFoldersFound -Property Name |
  #   Where-Object SideIndicator -match "=>" |
  #   Select-Object Name, Version, Directory

  $parsedExtensionFolders |
    Group-Object Name |
    Where-Object Count -GT 1 |
    # Where-Object LastWriteTime -GT $DATETIME_CUTOFF |
    ForEach-Object {
      $newest, $old = $_.Group

      $old.Directory
    } |
    # Flatten array of arrays
    ForEach-Object {
      $_
    }
}
