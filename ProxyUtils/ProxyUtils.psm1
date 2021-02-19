$PROXY_REGISTRY_PATH = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'

function Get-Proxy {
  [CmdletBinding()]
  param (
    [switch]
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
          Expression = {
            $_.ProxyOverride -split ";"
          }
        }
      )
    }
  }

  Get-ItemProperty -Path $PROXY_REGISTRY_PATH | Select-Object @arguments
}

function Enable-Proxy {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
  [Alias('proxy')]
  [OutputType([string])]
  Param
  (
    # server address
    [Parameter(Position = 0)]
    [String]
    $ProxyHost,
    # port number
    [Parameter(Position = 1)]
    [String]
    $ProxyPort,
    # Exclusions
    [Parameter(Position = 2)]
    [String[]]
    $Exclusions,
    [Switch]
    $ImportWinHttpProxy
  )

  process {
    $ProxyServer = "$($ProxyHost):$($ProxyPort)"

    #Test if the TCP Port on the server is open before applying the settings
    if (-not (Test-NetConnection -ComputerName $ProxyHost -Port $ProxyPort).TcpTestSucceeded) {
      Write-Error -Message "The proxy address is not valid: $ProxyServer"
    }
    else {
      if ($ProxyHost -and $ProxyHost) {
        Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyServer -Value $ProxyServer
      }
      if ($Exclusions) {
        Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyOverride -Value ($Exclusions -join ";")
      }
      Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyEnable -Value 1

      (ipconfig /flushdns && ipconfig /registerdns) |
        Out-String |
        Write-Verbose

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
    $ResetWinHttpProxy
  )

  if ($RemoveProxyServerAddress) {
    Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyServer -Value ""
  }
  Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyEnable -Value 0

  ipconfig /flushdns && ipconfig /registerdns |
    Out-String |
    Write-Verbose

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
