#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

# todo: move this module install into an environment setup script
# todo: environment setup script should install tranitive dependencies (consider using PSDepend to approximate npm shrinkwrap)
Install-Module IISSeries5 -RequiredVersion '0.1.0'



Import-Module IISSeries5 -MinimumVersion '0.1.0' -MaximumVersion '0.1.999'
Import-Module IISSecurity -MinimumVersion '0.1.0' -MaximumVersion '0.1.999'

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
