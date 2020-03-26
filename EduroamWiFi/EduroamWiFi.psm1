#Requires -RunAsAdministrator

function Clear-WiFiDnsCache {

  Write-Verbose "Flushing DNS cache"
  ipconfig -release "Wi-Fi" | Out-Null
  ipconfig -flushdns | Out-Null
  ipconfig -renew "Wi-Fi"
}

$INTERFACE_ALIAS = "Wi-Fi"

function Set-CorrectDnsServer {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
  param()

  throw "FIXME"

  $network = Get-NetConnectionProfile | Select-Object Name, InterfaceAlias

  if ($network.Name -match "eduroam") {
    $Interface = "Wi-Fi"
    $ServerName = "Default"

    Write-Output "Changing WiFi DNS Server to defaults"
  }
  elseif ($network.Name -eq "ThereThere") {
    $Interface = "Both"
    $ServerName = "Google"

    Write-Output "Changing WiFi and Ethernet DNS Server to Google"
  }
  else {
    throw "Unknown network $network"
  }

  if ($PSCmdlet.ShouldProcess("Set DNS Server automatically")) {
    Start-Process "pwsh" -Verb runAs -ArgumentList @(
      "-NoLogo"
      "-Command"
      "& ""$PSScriptRoot/../Scripts/Set-DnsServer.ps1"" -Interface $Interface -ServerName $ServerName; Start-Sleep -Seconds 5"
    )
  }
}

function Connect-EduroamWiFi {
  [CmdletBinding()]
  param ()

  # Write-Verbose "Disable IPv6 interface"
  # Disable-NetAdapterBinding -Name $INTERFACE_ALIAS -ComponentID ms_tcpip6

  Write-Verbose "Set DNS client to default"
  Set-DnsClientServerAddress -PassThru -InterfaceAlias "$INTERFACE_ALIAS" -ResetServerAddresses

  # Clear-WiFiDnsCache
}

function Disconnect-EduroamWiFi {
  [CmdletBinding()]
  param ()

  # Write-Verbose "Re-enable IPv6 interface"
  # Enable-NetAdapterBinding -Name $INTERFACE_ALIAS -ComponentID ms_tcpip6

  Write-Verbose "Set DNS client to Google"
  Set-DnsClientServerAddress -PassThru -InterfaceAlias "$INTERFACE_ALIAS" -ServerAddresses "8.8.8.8", "8.8.8.4", "2001:4860:4860::8888", "2001:4860:4860::8844"

  # Clear-WiFiDnsCache
}

Set-Alias change-dns "$PSScriptRoot/Scripts/Set-DnsServer.ps1"
Set-Alias Connect-HomeWiFi Disconnect-EduroamWiFi

$exports = @{
  Function = @(
    "Set-CorrectDnsServer"
    "Connect-EduroamWiFi"
    "Disconnect-EduroamWiFi"
  )
  Alias    = @(
    "change-dns"
    "Connect-HomeWiFi"
  )
}

Export-ModuleMember @exports
