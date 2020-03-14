$CONFIG_FOLDER = Get-Item "$env:PROJECTS_FOLDER/_CONFIGS/python"
$VENV_PATH = Get-Item "~/.virtualenvs/"

$TOOLS = @{
  Coverage = ".coveragerc"
  Mypy     = "mypy.ini"
  Pylint   = ".pylintrc"
  Pytest   = "pytest.ini"
  # Yapf     = ".style.yapf"
}

# XXX how to export types? ps1xml or "using" keyword?
Class ValidVenvNames : System.Management.Automation.IValidateSetValuesGenerator {
  [String[]] GetValidValues() {
    # XXX global bad?
    $venvs = Get-ChildItem $Script:VENV_PATH | Select-Object -ExpandProperty Name
    return [String[]] $venvs
  }
}

function Get-CurrentVirtualEnvs {
  Write-Output "Current virtualenvs`n"

  Get-ChildItem $Script:VENV_PATH | Select-Object -ExpandProperty Name
}

function Remove-VirtualEnv {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
  param (
    [Parameter(Mandatory = $true)]
    [ValidateSet([ValidVenvNames])]
    [String]
    $VenvName
  )

  if ($PSCmdlet.ShouldProcess($VenvName)) {
    $venvFullName = Join-Path $Script:VENV_PATH $VenvName | Get-Item

    # classic remove-item
    $venvFullName | Remove-Item -Recurse

    # TODO use pipenv --rm from project folder to remove a virtualenv
    # $projectFolderName = Join-Path $venvFullName ".project" | Get-Content
  }
}

function Remove-UnusedVirtualenvs {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
  param()

  process {
    Get-ChildItem $Script:VENV_PATH |
      Where-Object {
        $venv = $_
        $projectFolderName = Get-Content (Join-Path $venv.FullName ".project")

        -not (Test-Path $projectFolderName)
      } | ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.Name)) {
          Remove-Item -Recurse $_
        }
      }
  }
}

function Add-PythonConfigsHere {
  $Script:TOOLS.GetEnumerator() | ForEach-Object {
    $tool = $_.Name
    $configFilename = $_.Value
    $globalFile = Join-Path $Script:CONFIG_FOLDER $configFilename | Get-Item

    # New-Item -ItemType HardLink -Name $configFilename -Value $globalFile
    # Write-Output "hardlinked $tool"

    Copy-Item -Path $globalFile -Destination $configFilename
    Write-Output "copied $tool"
  }
}

Set-Alias ls-venvs Get-CurrentVirtualEnvs
Set-Alias rm-venv Remove-Virtualenv
Set-Alias prune-venvs Remove-UnusedVirtualenvs
