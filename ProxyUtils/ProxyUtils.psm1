$PROXY_REGISTRY_PATH = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'

function Get-NetProxy {
  [CmdletBinding()]
  param (
    [switch]
    $Raw
  )

  $rawObject = Get-ItemProperty -Path $PROXY_REGISTRY_PATH

  if ($Raw) {
    $rawObject
  }
  else {
    $arguments = @{
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


    $rawObject | Select-Object @arguments
    # $rawObject | Select-Object ProxyEnable, ProxyServer, @{Name = 'Exclusions'; Expression = { $_.ProxyOverride -split ";" } }
  }
}

function Set-NetProxy {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
  [Alias('proxy')]
  [OutputType([string])]
  Param
  (
    # server address
    # [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    [Parameter(Position = 0)]
    [String]
    $server,
    # port number
    # [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
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
    If (-not (Test-NetConnection -ComputerName $server -Port $port).TcpTestSucceeded) {
      Write-Error -Message "The proxy address is not valid: $($server):$($port)"
    }
    Else {
      if ($server -and $port) {
        Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyServer -Value "$($server):$($port)"
      }
      if ($exclusions) {
        Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyEnable -Value ($exclusions -join ";")
      }
      Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyEnable -Value 1
    }

    Get-NetProxy
  }
}

function Remove-NetProxy {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
  [Alias('Unset-NetProxy')]
  param (
    [switch]
    $RemoveProxyServerAddress
  )

  if ($RemoveProxyServerAddress) {
    Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyServer -Value ""
  }
  Set-ItemProperty -Path $PROXY_REGISTRY_PATH -name ProxyEnable -Value 0

  Get-NetProxy
}
