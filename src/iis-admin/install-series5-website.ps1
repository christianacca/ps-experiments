#Requires -RunAsAdministrator
#Requires -Modules Install-Utils

$ErrorActionPreference = 'Stop'

$RootPath = 'C:\Git\Series5'
$SiteName = 'Series5'
$SpaRelativeAppPath = 'src\Ram.Series5.Spa'
$WinLoginRelativeAppPath = 'src\Ram.Series5.WinLogin'
$Port = 80
$SitePhysicalPath = "C:\inetpub\sites\$SiteName"

. .\src\IISSecurity\Set-IISAppPoolIdentityAcl.ps1
. .\src\IISSecurity\Set-WebHardenedAcl.ps1
Install-CaccaMissingScript Add-Hostnames
Install-CaccaMissingScript Add-BackConnectionHostNames

# Declare script-wide constants/variables
$spaAppPath = Join-Path $RootPath $SpaRelativeAppPath
$winLoginAppPath = Join-Path $RootPath $WinLoginRelativeAppPath
$spaAppName = 'Spa'
$mainAppPoolName = 'Series5-AppPool'
# IMPORTANT: this must NOT use a . in the host name. Doing so would result in our site being classified into the 'internet'
# zone by IE and as a consequence any windows auth challenge would result in a native browser login popup
$spaHostName = 'local-series5'
$winLoginAppName = 'WinLogin'

[Microsoft.Web.Administration.ServerManager]$manager = Get-IISServerManager

# Delete existing
Start-IISCommitDelay
$existingSite = $manager.Sites[$SiteName];
if ($existingSite -ne $null) {
    $manager.Sites.Remove($existingSite)
}
$existingPool = $manager.ApplicationPools[$mainAppPoolName];
if ($existingPool -ne $null) {
    $manager.ApplicationPools.Remove($existingPool)
}
Stop-IISCommitDelay

# Create top level website with apps
# Reset-IISServerManager -Confirm:$false
if (-not(Test-Path $SitePhysicalPath)) {
    New-Item $SitePhysicalPath -ItemType Directory | Out-Null
}
Start-IISCommitDelay
$pool = $manager.ApplicationPools.Add($mainAppPoolName)
$pool.ManagedPipelineMode = "Integrated"
$pool.ManagedRuntimeVersion = "v4.0"
$pool.Enable32BitAppOnWin64 = $true
$pool.AutoStart = $true
$site = New-IISSite -Name $SiteName -BindingInformation "*:$($Port):$($spaHostName)" -PhysicalPath $SitePhysicalPath -Passthru
$site.Applications["/"].ApplicationPoolName = $mainAppPoolName

# Unlock sections in applicationHost.config
Unlock-CaccaIISWindowsAuth -Location "$SiteName/$winLoginAppName" -Minimum -ServerManager $manager
Unlock-CaccaIISAnonymousAuth -Location "$SiteName/$winLoginAppName" -ServerManager $manager
Unlock-CaccaIISAnonymousAuth -Location "$SiteName/$spaAppName" -ServerManager $manager
Unlock-CaccaIISConfigSection -SectionPath 'system.webServer/rewrite/allowedServerVariables' -Location "$SiteName/$spaAppName" -ServerManager $manager

# Create SPA child application
$spaApp = $site.Applications.Add("/$spaAppName", $spaAppPath)
$spaApp.ApplicationPoolName = $mainAppPoolName

# Create WinLogin child app
$winLoginApp = $site.Applications.Add("/$winLoginAppName", $winLoginAppPath)
$winLoginApp.ApplicationPoolName = $mainAppPoolName

Stop-IISCommitDelay

# register hostname so that local DNS resolves the website host name to the IP of this machine
Add-Hostnames '127.0.0.1' $spaHostName
# this is required for windows auth to work when host name "loops back" to the same machine
Add-BackConnectionHostNames $spaHostName

# Set file access permissions

Set-WebHardenedAcl -Path $RootPath -SiteAdminsGroup 'BSW\Series5000Dev Group'
Set-WebHardenedAcl -Path $SitePhysicalPath -SiteAdminsGroup 'BSW\Series5000Dev Group'

# file permissions: grant $AppPoolName sufficient to Spa virtual directory
$spaAclParams = @{
    SitePath = $SitePhysicalPath
    AppPath = $spaAppPath
    AppPoolName = $mainAppPoolName
    AppPathsWithModifyPerms = @('App_Data', 'Series5Seed\screens')
    AppPathsWithExecPerms = @('UDFs\PropertyBuilder.exe')
}
Set-IISAppPoolIdentityAcl @spaAclParams

# file permissions: grant $AppPoolName sufficient to WinLogin virtual directory
$winLoginAclParams = @{
    AppPath = $winLoginAppPath
    AppPoolName = $mainAppPoolName
    AppPathsWithModifyPerms = @('App_Data')
}
Set-IISAppPoolIdentityAcl @winLoginAclParams