#Requires -RunAsAdministrator
#Requires -Modules Install-Utils

$ErrorActionPreference = 'Stop'
# $VerbosePreference = 'Continue'

$RootPath = 'C:\Git\Series5'
$SiteName = 'Series5'
$SpaRelativeAppPath = 'src\Ram.Series5.Spa'
$WinLoginRelativeAppPath = 'src\Ram.Series5.WinLogin'
$SitePhysicalPath = "C:\inetpub\sites\$SiteName"

Import-Module '.\src\IISSecurity\IISSecurity' -Force
# Install-CaccaMissingModule IISSecurity -AutoImport
Install-CaccaMissingScript Add-Hostnames
Install-CaccaMissingScript Add-BackConnectionHostNames

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

[Microsoft.Web.Administration.ServerManager]$manager = Get-IISServerManager

# Remove site
Start-IISCommitDelay
$existingSite = $manager.Sites[$SiteName];
$manager.Sites.Remove($existingSite)
$existingPool = $manager.ApplicationPools[$mainAppPoolName];
$manager.ApplicationPools.Remove($existingPool)
Stop-IISCommitDelay

# Remove hostname from environment
Remove-Hostnames $spaHostName
Remove-BackConnectionHostNames $spaHostName