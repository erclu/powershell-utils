$PROXY_REGISTRY_PATH = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'

function Get-Proxy {
  [CmdletBinding()]
  param (
    [Switch]
    $Raw,
    [Switch]
    $ShowWinHttpProxy
  )

  $arguments = if ($Raw) {
    @{ Property = '*' }
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
          Expression = { $_.ProxyOverride -split ';' }
        }
      )
    }
  }

  Get-ItemProperty -Path $PROXY_REGISTRY_PATH | Select-Object @arguments

  Write-Output "all_proxy: $($env:all_proxy)"
  Write-Output "no_proxy: $($env:no_proxy)"

  if ($ShowWinHttpProxy) {
    netsh winhttp show proxy
  }
}

function Enable-Proxy {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
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
    [Switch]
    $FlushDns,
    [Switch]
    $IncludeWsl
  )

  process {
    $ProxyServer = "$($ProxyHost):$($ProxyPort)"

    #Test if the TCP Port on the server is open before applying the settings
    if (-not (Test-NetConnection -ComputerName $ProxyHost -Port $ProxyPort).TcpTestSucceeded) {
      Write-Error -Message "The proxy address is not valid: $ProxyServer"
      Write-Output 'Press any key to continue...'
      $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
    else {
      Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyEnable -Value 1
      Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyServer -Value $ProxyServer
      Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyOverride -Value ($Exclusions -join ';')

      $ProxyUrl = "http://$ProxyServer"

      $env:all_proxy = $ProxyUrl
      $env:http_proxy = $ProxyUrl
      $env:https_proxy = $ProxyUrl
      $env:no_proxy = $Exclusions -join ','
      [Environment]::SetEnvironmentVariable('all_proxy', $env:all_proxy, 'User')
      [Environment]::SetEnvironmentVariable('http_proxy', $env:http_proxy, 'User')
      [Environment]::SetEnvironmentVariable('https_proxy', $env:https_proxy, 'User')
      [Environment]::SetEnvironmentVariable('no_proxy', $env:no_proxy , 'User')

      if ($IncludeWsl) {
        wsl -d ubuntu -- bash -i -c 'enable-proxy'
      }

      if ($FlushDns) {
        (ipconfig /flushdns && ipconfig /registerdns) | Write-Output
      }

      if ($ImportWinHttpProxy) {
        Import-WinHttpProxyFromIeProxy
      }
    }

    Get-Proxy
  }
}

function Disable-Proxy {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param (
    [switch]
    $RemoveProxySettings,
    [switch]
    $ResetWinHttpProxy,
    [switch]
    $FlushDns,
    [Switch]
    $IncludeWsl
  )

  Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyEnable -Value 0

  [Environment]::SetEnvironmentVariable('all_proxy', $null, 'User')
  [Environment]::SetEnvironmentVariable('http_proxy', $null, 'User')
  [Environment]::SetEnvironmentVariable('https_proxy', $null, 'User')
  [Environment]::SetEnvironmentVariable('no_proxy', $null, 'User')

  # Remove from current shell if present
  @(
    'Env:\all_proxy'
    'Env:\http_proxy'
    'Env:\https_proxy'
    'Env:\no_proxy'
  ) | Where-Object { Test-Path $_ } | Remove-Item

  if ($RemoveProxySettings) {
    Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyServer -Value ''
    Set-ItemProperty -Path $PROXY_REGISTRY_PATH -Name ProxyOverride -Value ''
  }

  if ($IncludeWsl) {
    wsl -d ubuntu -- bash -i -c 'disable-proxy'
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
  # [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
  [CmdletBinding()]
  param ()

  sudo netsh winhttp import proxy source=ie
}

function Reset-WinHttpProxy {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  [CmdletBinding()]
  param ()

  if ($PSCmdlet.ShouldProcess('Reset WinHTTP proxy settings?')) {
    sudo netsh winhttp reset proxy
  }
}

# TODO test me
# TODO reduce duplication
function New-ProxyShortcuts {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param (
    [Parameter(Position = 0)]
    [System.IO.DirectoryInfo]
    $Destination = '.',
    [Switch]
    $EnableShortcut,
    [Switch]
    $DisableShortcut
  )
  if (-not($PSCmdlet.ShouldProcess('Create shortcuts?'))) {
    return
  }

  $WshShell = New-Object -ComObject WScript.Shell

  if ($EnableShortcut) {
    $Shortcut = $WshShell.CreateShortcut("$Destination\enable-proxy.lnk")
    $Shortcut.TargetPath = 'pwsh.exe -NoLogo -Command "Enable-Proxy -ImportWinHttpProxy -IncludeWsl"'
    $Shortcut.Save()
  }
  if ($DisableShortcut) {
    $Shortcut = $WshShell.CreateShortcut("$Destination\disable-proxy.lnk")
    $Shortcut.TargetPath = 'pwsh.exe -NoLogo -Command "Disable-Proxy -FlushDns -ResetWinHttpProxy -IncludeWsl"'
    $Shortcut.Save()
  }
}
