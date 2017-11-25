#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'


$RootPath = 'C:\Git\Series5'
$SiteName = 'Series5'
$SpaRelativeAppPath = 'src\Ram.Series5.Spa'
$WinLoginRelativeAppPath = 'src\Ram.Series5.WinLogin'
$SitePhysicalPath = "C:\inetpub\sites\$SiteName"

Import-Module '.\src\IISSiteInstall\IISSiteInstall\IISSiteInstall.psd1'
Install-Module IISConfigUnlock -RequiredVersion '0.1.0'
Import-Module IISConfigUnlock -MinimumVersion '0.1.0' -MaximumVersion '0.1.999'

# Declare script-wide constants/variables
$spaAppPath = Join-Path $RootPath $SpaRelativeAppPath
$winLoginAppPath = Join-Path $RootPath $WinLoginRelativeAppPath
# IMPORTANT: this must NOT use a . in the host name. Doing so would result in our site being classified into the 'internet'
# zone by IE and as a consequence any windows auth challenge would result in a native browser login popup
$HostName = 'local-series5'

# Create top level website
$siteParams = @{
    Name                     = $SiteName
    Path                     = $SitePhysicalPath
    HostName                 = $HostName
    SiteShellOnly            = $true
    HostsFileIPAddress       = '127.0.0.1'
    AddHostToBackConnections = $true
    AppPoolName              = 'Series5-AppPool'
}
New-CaccaIISWebsite @siteParams -Force

# Create SPA child application
$spaParams = @{
    SiteName     = $SiteName
    Name         = 'Spa'
    Path         = $spaAppPath
    ModifyPaths  = @('App_Data', 'Series5Seed\screens', 'UDFs', 'bin')
    ExecutePaths = @('UDFs\PropertyBuilder.exe')
}
New-CaccaIISWebApp @spaParams -Config {
    Unlock-CaccaIISAnonymousAuth -Location "$SiteName$($_.Path)" -Commit:$false
    Unlock-CaccaIISConfigSection -SectionPath 'system.webServer/rewrite/allowedServerVariables' -Location "$SiteName$($_.Path)" -Commit:$false    
}

# Create WinLogin child app
$winLoginParams = @{
    SiteName = $SiteName
    Name     = 'WinLogin'
    Path     = $winLoginAppPath
}
New-CaccaIISWebApp @winLoginParams -Config {
    Unlock-CaccaIISWindowsAuth -Location "$SiteName$($_.Path)" -Minimum -Commit:$false
    Unlock-CaccaIISAnonymousAuth -Location "$SiteName$($_.Path)" -Commit:$false
}

# Harden webserver
Set-CaccaWebHardenedAcl -Path $RootPath -SiteAdminsGroup 'BSW\Series5000Dev Group'
Set-CaccaWebHardenedAcl -Path $SitePhysicalPath -SiteAdminsGroup 'BSW\Series5000Dev Group'
