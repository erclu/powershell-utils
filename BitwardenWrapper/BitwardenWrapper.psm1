function Unlock-BitwardenDatabase {
  [CmdletBinding()]
  param ()

  $WRONG_MASTER_PASSWORD = 'Invalid master password.'
  $EMPTY_MASTER_PASSWORD = 'Master password is required.'

  if ($env:BW_SESSION) {
    Write-Output "Bitwarden database was already unlocked"
    return
  }

  $SESSION = bw unlock --raw

  if (Get-Module PSReadLine) {
    Write-Verbose "Removing PSReadline module"
    Remove-Module PSReadLine
  }

  if ($SESSION -match $WRONG_MASTER_PASSWORD -or $SESSION -match $EMPTY_MASTER_PASSWORD) {
    Throw "Unlock failed"
  }

  Write-Output "Bitwarden database unlocked"

  # remember current session
  Write-Verbose "Saving session key to environment variable"
  $env:BW_SESSION = $SESSION
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

  return $null -ne ($SensitiveWords | Where-Object { $InputString -match $_ } | Select-Object -First 1)
}

# Unlock-BitwardenDatabase
