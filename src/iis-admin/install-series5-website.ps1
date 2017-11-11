#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Install-Module IISSecurity -RequiredVersion '0.1.0'
Install-Module IISConfigUnlock -RequiredVersion '0.1.0'
Install-Module HostNameUtils -RequiredVersion '1.0.0'


$RootPath = 'C:\Git\Series5'
$SiteName = 'Series5'
$SpaRelativeAppPath = 'src\Ram.Series5.Spa'
$WinLoginRelativeAppPath = 'src\Ram.Series5.WinLogin'
$SitePhysicalPath = "C:\inetpub\sites\$SiteName"
$Port = 80

Import-Module IISSecurity -MinimumVersion '0.1.0' -MaximumVersion '0.1.999'
Import-Module IISConfigUnlock -MinimumVersion '0.1.0' -MaximumVersion '0.1.999'
Import-Module HostNameUtils -MinimumVersion '1.0.0' -MaximumVersion '1.999.999'

# Declare script-wide constants/variables
$spaAppPath = Join-Path $RootPath $SpaRelativeAppPath
$winLoginAppPath = Join-Path $RootPath $WinLoginRelativeAppPath
$spaAppName = 'Spa'
$mainAppPoolName = 'Series5-AppPool'
# IMPORTANT: this must NOT use a . in the host name. Doing so would result in our site being classified into the 'internet'
# zone by IE and as a consequence any windows auth challenge would result in a native browser login popup
$spaHostName = 'local-series5'
$winLoginAppName = 'WinLogin'


# Delete existing
[Microsoft.Web.Administration.ServerManager]$manager = Get-IISServerManager
Start-IISCommitDelay
$existingSite = $manager.Sites[$SiteName];
if ($existingSite -ne $null) {
    $manager.Sites.Remove($existingSite)
}
$existingPool = $manager.ApplicationPools[$mainAppPoolName];
if ($existingPool -ne $null) {
    $manager.ApplicationPools.Remove($existingPool)
}


# Create top level website
if (-not(Test-Path $SitePhysicalPath)) {
    New-Item $SitePhysicalPath -ItemType Directory | Out-Null
}

$pool = $manager.ApplicationPools.Add($mainAppPoolName)
$pool.ManagedPipelineMode = "Integrated"
$pool.ManagedRuntimeVersion = "v4.0"
$pool.Enable32BitAppOnWin64 = $true
$pool.AutoStart = $true
$site = New-IISSite -Name $SiteName -BindingInformation "*:$($Port):$($spaHostName)" -PhysicalPath $SitePhysicalPath -Passthru
$site.Applications["/"].ApplicationPoolName = $mainAppPoolName

$siteShellAclParams = @{
    SitePath      = $SitePhysicalPath
    AppPoolName   = $mainAppPoolName
    SiteShellOnly = $true
}
Set-CaccaIISSiteAcl @siteShellAclParams

# Create SPA child application
$spaApp = $site.Applications.Add("/$spaAppName", $spaAppPath)
$spaApp.ApplicationPoolName = $mainAppPoolName
Unlock-CaccaIISAnonymousAuth -Location "$SiteName/$spaAppName" -Commit:$false
Unlock-CaccaIISConfigSection -SectionPath 'system.webServer/rewrite/allowedServerVariables' -Location "$SiteName/$spaAppName" -Commit:$false

$spaAclParams = @{
    AppPath      = $spaAppPath
    AppPoolName  = $mainAppPoolName
    ModifyPaths  = @('App_Data', 'Series5Seed\screens', 'UDFs', 'bin')
    ExecutePaths = @('UDFs\PropertyBuilder.exe')
}
Set-CaccaIISSiteAcl @spaAclParams


# Create WinLogin child app
$winLoginApp = $site.Applications.Add("/$winLoginAppName", $winLoginAppPath)
$winLoginApp.ApplicationPoolName = $mainAppPoolName
Unlock-CaccaIISWindowsAuth -Location "$SiteName/$winLoginAppName" -Minimum -Commit:$false
Unlock-CaccaIISAnonymousAuth -Location "$SiteName/$winLoginAppName" -Commit:$false

$winLoginAclParams = @{
    AppPath     = $winLoginAppPath
    AppPoolName = $mainAppPoolName
    ModifyPaths = @('App_Data')
}
Set-CaccaIISSiteAcl @winLoginAclParams
Stop-IISCommitDelay


# register hostname so that local DNS resolves the website host name to the IP of this machine
Add-TecBoxHostnames '127.0.0.1' $spaHostName
# this is required for windows auth to work when host name "loops back" to the same machine
Add-TecBoxBackConnectionHostNames $spaHostName

# Harden webserver
Set-CaccaWebHardenedAcl -Path $RootPath -SiteAdminsGroup 'BSW\Series5000Dev Group'
Set-CaccaWebHardenedAcl -Path $SitePhysicalPath -SiteAdminsGroup 'BSW\Series5000Dev Group'
