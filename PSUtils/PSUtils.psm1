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
    'cache size (MB)'          = [math]::Round($cache / 1MB, 2)
    'persisted data size (MB)' = [math]::Round($persisted / 1MB, 2)
    'installed apps size (GB)' = [math]::Round($installed / 1GB, 2)
  }
}

function Update-EverythingHaphazardly {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param ()

  if (-not $PSCmdlet.ShouldProcess('Update apps')) {
    return
  }

  if (Get-Command -ErrorAction SilentlyContinue pipx) {
    Write-Output ('-' * $Host.UI.RawUI.WindowSize.Width)
    Write-Output '- Updating pipx packages'

    pipx upgrade-all
  }

  if (Get-Command -ErrorAction SilentlyContinue npm) {
    Write-Output ('-' * $Host.UI.RawUI.WindowSize.Width)
    Write-Output '- Outdated npm global packages'
    npm outdated -g

    Write-Output '- Updating npm global packages'
    npm update -g
  }

  Update-ScoopAndCleanAfter

  Update-GitRepositoriesSafely
}

function Update-ScoopAndCleanAfter {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param ()

  Write-Output ('-' * $Host.UI.RawUI.WindowSize.Width)
  Write-Output '- Updating scoop packages'

  $telegram = 'telegram'

  scoop update 6>&1 | Write-Verbose

  $status_output = scoop status 6>&1
  $status_output
  if ($status_output -match $telegram) {
    Write-Output '- Stopping telegram...'
    Get-Process $telegram | Stop-Process
  }

  if ($PSCmdlet.ShouldProcess('Update apps')) {
    scoop update *
  }

  Write-Output '- Running scoop cleanup...'
  scoop cleanup *

  Write-Output '- Clearing cache...'
  scoop cache show
  scoop cache rm *

  if ($out -match $telegram) {
    Write-Output '- Starting telegram...'
    & $telegram
  }
}

function Update-GitRepositoriesSafely {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, Position = 0)]
    [System.IO.DirectoryInfo[]]
    $Repositories
  )

  Write-Error 'NOT IMPLEMENTED'
  return

  if (-not $PSCmdlet.ShouldProcess('Update apps')) {
    Write-Output 'Really?? Running git fetch is less risky than '
  }
  foreach ($repo in $Repositories) {

    git -C $repo fetch --all
    # TODO can i use status -s here??
    git -C $repo status
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
    Where-Object FullName -NotMatch '.zip' |
    Where-Object FullName -NotMatch '.git' |
    Where-Object FullName -NotMatch '.mypy_cache' |
    Where-Object FullName -NotMatch 'node_modules' |
    Where-Object FullName -NotMatch 'vendor' |
    Where-Object { -not (Test-ContainsBOM $_) } |
    Select-Object FullName
}

function Get-BranchAndSha {
  param ()

  "$(git branch --show-current)-$(git rev-parse --short HEAD)"
}

function Find-Duplicates {
  [CmdletBinding()]
  param (
    [Parameter()]
    [String[]]
    $Paths = '.'
  )
  python 'D:/Projects/__libraries-wheels-etc/find_duplicates.py' $Paths
}

function New-TemporaryDirectory {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
  param()

  if ($PSCmdlet.ShouldProcess('Create new temporary directory')) {
    New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid()))
  }
}

# function New-FastTemporaryDirectory {
#   [string] $name = [System.Guid]::NewGuid()
#   New-Item -ItemType Directory -Path ("C:/TEMP-$name")
# }

########################################################################################################################
####################################### Hardlinks utils
########################################################################################################################

function New-HardLink {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  Param(
    [parameter(position = 0)] [String] $Name,
    [parameter(position = 1)] [Object] $Value
  )

  if ($PSCmdlet.ShouldProcess('Create new HardLink')) {
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

  Get-Content '~/.ssh/id_rsa.pub' | ssh $Destination 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
}


function Add-ModuleShim {
  [CmdletBinding()]
  param (
    [System.IO.DirectoryInfo]
    $ModuleFolder
  )

  $ModuleFullPath = $ModuleFolder.FullName
  $ShimPath = Join-Path "$HOME/Documents/PowerShell/Modules/" $ModuleFolder.Name

  New-Item -ItemType Junction -Path $ShimPath -Value $ModuleFullPath -Confirm
}

function Get-OldVsCodeExtensions {
  [CmdletBinding()]
  param (
    [System.IO.DirectoryInfo]
    $VscodeExtensionsDirectory = (Get-Item 'C:/Tools/vscode/data/extensions')
  )

  $SEMVER_REGEX = '(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-((?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?'
  $SPLITTER_REGEX = "^(?<name>.*?)-(?<version>$SEMVER_REGEX)$"

  # if (-not $Aggro) {
  # $DATETIME_CUTOFF = (Get-Date).AddDays(-7)
  # }
  # else {
  # $DATETIME_CUTOFF = Get-Date
  # }

  $parsedExtensionFolders = @(
    Get-ChildItem -Directory -Path $VscodeExtensionsDirectory |
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

function Invoke-GitGcWithReflogExpire {
  [CmdletBinding()]
  [Alias('git-gc-expire-unreachable')]
  param (
    # Work tree of the repository where git gc should be invoked
    [Parameter(Position = 0)]
    [System.IO.DirectoryInfo]
    $Path = '.'
  )

  process {
    git -C $Path reflog expire --expire-unreachable=now --all
    git -C $Path gc --aggressive --prune=now
  }
}

function Update-VsCodePortable {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
  param (
    [Parameter(Mandatory, Position = 0)]
    [System.IO.DirectoryInfo]
    $Destination,
    [Parameter(Mandatory)]
    [System.IO.DirectoryInfo]
    $DataFolder,
    [Switch]
    $Force
  )

  if (-not $PSCmdlet.ShouldProcess('UPDATE VSCODE PORTABLE?')) {
    return
  }

  $allProducts = Invoke-WebRequest 'https://code.visualstudio.com/sha?build=stable' |
    Select-Object -ExpandProperty Content |
    ConvertFrom-Json |
    Select-Object -ExpandProperty 'products'

  $winPortableProduct = $allProducts | Where-Object { $_.platform.os -match 'win32-x64-archive' }

  $readableInstalledVersion = (code -v)[0]
  $installedVersionHash = (code -v)[1]

  if (-not $Force -and $winPortableProduct.version -match $installedVersionHash) {
    Write-Output "VSCode is up to date. Current version is $($winPortableProduct.name)"
    return
  }

  Write-Output 'Shutting down wsl just to be sure'
  wsl --shutdown

  if (Test-Path $Destination) {
    $backupFolder = "$($Destination.Name)-$readableInstalledVersion"

    if (Test-Path (Join-Path $Destination $backupFolder)) {
      throw 'Backup folder already exists'
    }

    Write-Output "Backing up current content of $Destination $backupFolder"
    Rename-Item $Destination -NewName $backupFolder -ErrorAction Stop
  }

  # TODO cache downloaded archive
  $archive = New-TemporaryFile
  Invoke-WebRequest $winPortableProduct.url -OutFile $archive

  # TODO check hash

  Expand-Archive -Path $archive -DestinationPath $Destination

  New-Item -ItemType Junction -Path (Join-Path $Destination 'data') -Target (Resolve-Path $DataFolder)
}

function Edit-HostsFile {
  [CmdletBinding()]
  param ()

  sudo notepad c:\windows\system32\drivers\etc\hosts
}
