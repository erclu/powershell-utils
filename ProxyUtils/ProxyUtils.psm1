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
    $server,
    # port number
    [Parameter(Position = 1)]
    [String]
    $port,
    # exclusions
    [Parameter(Position = 2)]
    [String[]]
    $exclusions
  )

  process {
    #Test if the TCP Port on the server is open before applying the settings
    if (-not (Test-NetConnection -ComputerName $server -Port $port).TcpTestSucceeded) {
      Write-Error -Message "The proxy address is not valid: $($server):$($port)"
    }
    else {
      if ($server -and $port) {
        Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyServer -Value "$($server):$($port)"
      }
      if ($exclusions) {
        Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyEnable -Value ($exclusions -join ";")
      }
      Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyEnable -Value 1
    }

    Get-Proxy
  }
}

function Disable-Proxy {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
  param (
    [switch]
    $RemoveProxyServerAddress
  )

  if ($RemoveProxyServerAddress) {
    Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyServer -Value ""
  }
  Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyEnable -Value 0

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
