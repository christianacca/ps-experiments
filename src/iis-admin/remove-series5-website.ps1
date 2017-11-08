#Requires -RunAsAdministrator
#Requires -Modules Install-Utils

$ErrorActionPreference = 'Stop'

Import-Module InstallUtils # note: auto-loading not working for custom module

$RootPath = 'C:\Git\Series5'
$SiteName = 'Series5'
$SpaRelativeAppPath = 'src\Ram.Series5.Spa'
$WinLoginRelativeAppPath = 'src\Ram.Series5.WinLogin'
$SitePhysicalPath = "C:\inetpub\sites\$SiteName"

Install-CaccaMissingModule IISSecurity
Install-CaccaMissingScript Add-Hostnames
Install-CaccaMissingScript Add-BackConnectionHostNames

# note: auto-loading not working for custom module
Import-Module IISSecurity

# Declare script-wide constants/variables
$spaAppPath = Join-Path $RootPath $SpaRelativeAppPath
$winLoginAppPath = Join-Path $RootPath $WinLoginRelativeAppPath
$mainAppPoolName = 'Series5-AppPool'
$spaHostName = 'local-series5'

# remove file permissions
$spaAclParams = @{
    SitePath     = $SitePhysicalPath
    AppPath      = $spaAppPath
    AppPoolName  = $mainAppPoolName 
    ModifyPaths  = @('App_Data', 'Series5Seed\screens', 'UDFs', 'bin')
    ExecutePaths = @('UDFs\PropertyBuilder.exe')
}
Remove-CaccaIISSiteAcl @spaAclParams
$winLoginAclParams = @{
    AppPath     = $winLoginAppPath
    AppPoolName = $mainAppPoolName 
    ModifyPaths = @('App_Data')
}
Remove-CaccaIISSiteAcl @winLoginAclParams

# Remove site
[Microsoft.Web.Administration.ServerManager]$manager = Get-IISServerManager
Start-IISCommitDelay
$existingSite = $manager.Sites[$SiteName];
$manager.Sites.Remove($existingSite)
$existingPool = $manager.ApplicationPools[$mainAppPoolName];
$manager.ApplicationPools.Remove($existingPool)
Stop-IISCommitDelay

# Remove hostname from environment
Remove-Hostnames $spaHostName
Remove-BackConnectionHostNames $spaHostName