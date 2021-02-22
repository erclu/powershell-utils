$PROXY_REGISTRY_PATH = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'

function Get-Proxy {
  [CmdletBinding()]
  param (
    [Switch]
    $Raw
  )

  $arguments = if ($Raw) {
    @{ Property = "*" }
  }
  else {
    @{
      Property = @(@{
          Name       = 'IsEnabled'
          Expression = { $_.ProxyEnable -eq 1 }
        }
        @{
          Name       = 'Server Address'
          Expression = { $_.ProxyServer }
        }
        @{
          Name       = 'Exclusions'
          Expression = { $_.ProxyOverride -split ";" }
        }
      )
    }
  }

  Get-ItemProperty -Path $PROXY_REGISTRY_PATH | Select-Object @arguments
}

function Enable-Proxy {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
  Param
  (
    # server address
    [Parameter(Position = 0, Mandatory)]
    [String]
    $ProxyHost,
    # port number
    [Parameter(Position = 1, Mandatory)]
    [String]
    $ProxyPort,
    # Exclusions
    [Parameter(Position = 2)]
    [String[]]
    $Exclusions,
    [Switch]
    $ImportWinHttpProxy,
    [switch]
    $FlushDns
  )

  process {
    $ProxyServer = "$($ProxyHost):$($ProxyPort)"

    #Test if the TCP Port on the server is open before applying the settings
    if (-not (Test-NetConnection -ComputerName $ProxyHost -Port $ProxyPort).TcpTestSucceeded) {
      Write-Error -Message "The proxy address is not valid: $ProxyServer"
    }
    else {
      Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyEnable -Value 1
      Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyServer -Value $ProxyServer
      Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyOverride -Value ($Exclusions -join ";")

      if ($FlushDns) {
        (ipconfig /flushdns && ipconfig /registerdns) |
          Out-String |
          Write-Verbose
      }

      if ($ImportWinHttpProxy) {
        Import-WinHttpProxyFromIeProxy
      }
    }

    Get-Proxy
  }
}

function Disable-Proxy {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
  param (
    [switch]
    $RemoveProxyServerAddress,
    [switch]
    $ResetWinHttpProxy,
    [switch]
    $FlushDns
  )

  Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyEnable -Value 0

  if ($RemoveProxyServerAddress) {
    Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyServer -Value ""
  }

  if ($FlushDns) {
    ipconfig /flushdns && ipconfig /registerdns |
      Out-String |
      Write-Verbose
  }

  if ($ResetWinHttpProxy) {
    Reset-WinHttpProxy
  }

  Get-Proxy
}

function Import-WinHttpProxyFromIeProxy {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
  param ()

  sudo netsh winhttp import proxy source=ie
}

function Reset-WinHttpProxy {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
  param ()

  sudo netsh winhttp reset proxy
}
