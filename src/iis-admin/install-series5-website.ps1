#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Invoke-PSDepend -Install -Import -Force -WA SilentlyContinue

$devRoot = 'C:\Git\Series5'

# IMPORTANT: 'HostName' must NOT use a . in the host name. Doing so would result in our site being classified into the 'internet'
# zone by IE and as a consequence any windows auth challenge would result in a native browser login popup
$params = @{
    AppPath  = "$devRoot\src\Ram.Series5.Spa"
    WinLoginAppPath  = "$devRoot\src\Ram.Series5.WinLogin"
    HostName = 'local-series5'
    LocalDns = $true
}
$site = New-RamIISSeries5Spa @params
$sitePath = ($site).Applications['/'].VirtualDirectories['/'].PhysicalPath

# Harden webserver
Set-CaccaWebHardenedAcl -Path $devRoot -SiteAdminsGroup 'BSW\Series5000Dev Group'
Set-CaccaWebHardenedAcl -Path $sitePath -SiteAdminsGroup 'BSW\Series5000Dev Group'
