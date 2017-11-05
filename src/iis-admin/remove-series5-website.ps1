#Requires -RunAsAdministrator
#Requires -Modules Install-Utils

$ErrorActionPreference = 'Stop'
# $VerbosePreference = 'Continue'

$RootPath = 'C:\Git\Series5'
$SiteName = 'Series5'
$SpaRelativeAppPath = 'src\Ram.Series5.Spa'
$WinLoginRelativeAppPath = 'src\Ram.Series5.WinLogin'
$SitePhysicalPath = "C:\inetpub\sites\$SiteName"

. .\src\IISSecurity\Remove-IISSiteAcl.ps1
. .\src\scratch\Install-MissingScript.ps1

Install-MissingScript Add-Hostnames
Install-MissingScript Add-BackConnectionHostNames

# Declare script-wide constants/variables
$spaAppPath = Join-Path $RootPath $SpaRelativeAppPath
$winLoginAppPath = Join-Path $RootPath $WinLoginRelativeAppPath
$mainAppPoolName = 'Series5-AppPool'
$spaHostName = 'local-series5'

# remove file permissions
$spaAclParams = @{
    SitePath                = $SitePhysicalPath
    AppPath                 = $spaAppPath
    AppPoolName             = $mainAppPoolName 
    AppPathsWithModifyPerms = @('App_Data', 'Series5Seed\screens', 'UDFs')
    AppPathsWithExecPerms   = @('UDFs\PropertyBuilder.exe')
}
Remove-IISSiteAcl @spaAclParams
$winLoginAclParams = @{
    AppPath                 = $winLoginAppPath
    AppPoolName             = $mainAppPoolName 
    AppPathsWithModifyPerms = @('App_Data')
}
Remove-IISSiteAcl @winLoginAclParams

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