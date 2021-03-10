# $CONFIG = [PSCustomObject]@{}
$BITWARDEN_WRAPPER_MESSAGES = [PSCustomObject]@{
  ALREADY_UNLOCKED      = 'Bitwarden database was already unlocked'
  WRONG_MASTER_PASSWORD = 'Invalid master password.'
  EMPTY_MASTER_PASSWORD = 'Master password is required.'
  NOT_LOGGED_IN         = 'No user logged in.'
}
function Unlock-BitwardenDatabase {
  [CmdletBinding()]
  [Alias("bw-unlock")]
  param (
    [Switch]
    $RemovePSReadline
  )

  $status = bw status | ConvertFrom-Json | Select-Object -ExpandProperty status
  if ($status -eq "unlocked") {
    Write-Warning $BITWARDEN_WRAPPER_MESSAGES.ALREADY_UNLOCKED
    return
  }

  $bwUnlockOutput = bw unlock --raw

  if (-not $LASTEXITCODE -eq 0) {
    return
  }

  if ($RemovePSReadline -and (Get-Module PSReadLine)) {
    Write-Output "Removing PSReadline module from current session..."
    Remove-Module PSReadLine
  }

  Write-Output "Bitwarden database unlocked"

  # remember current session
  Write-Verbose "Saving session key to environment variable"
  $env:BW_SESSION = $bwUnlockOutput
}

Get-ChildItem -Recurse -File -LiteralPath "$PSScriptRoot/Classes" | ForEach-Object {
  . $_.FullName
}

function Get-BitwardenDatabase {
  [CmdletBinding()]
  param ()

  $lastSync = (Get-Date) - (Get-Date (bw sync --last))
  if ($lastSync -ge [timespan]::FromMinutes(5)) {
    Write-Verbose "Syncing db"
    bw sync | Out-Null
  }
  else {
    Write-Verbose "Using cached db"
  }

  $rawOutput = bw list items
  return " { `"root`":$rawOutput }" | ConvertFrom-Json | Select-Object -ExpandProperty root
  # TODO cast to classes defined in Classes.ps1?
}

function Test-ContainsSensitiveWords {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [String]
    $InputString,
    [Parameter(Mandatory)]
    [String[]]
    $SensitiveWords
  )

  process {
    Write-Output "matching each of $SensitiveWords against $InputString"

    return $null -ne ($SensitiveWords | Where-Object { $InputString -match $SensitiveWords } | Select-Object -First 1)
  }

}

# Unlock-BitwardenDatabase
