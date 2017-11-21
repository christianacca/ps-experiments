#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Install-Module IISSecurity -RequiredVersion '0.1.0'
Install-Module HostNameUtils -RequiredVersion '1.0.0'


$RootPath = 'C:\Git\Series5'
$SiteName = 'Series5'
$SpaRelativeAppPath = 'src\Ram.Series5.Spa'
$WinLoginRelativeAppPath = 'src\Ram.Series5.WinLogin'
$SitePhysicalPath = "C:\inetpub\sites\$SiteName"

Import-Module IISSecurity -MinimumVersion '0.1.0' -MaximumVersion '0.1.999'
Import-Module HostNameUtils -MinimumVersion '1.0.0' -MaximumVersion '1.999.999'

# Declare script-wide constants/variables
$spaAppPath = Join-Path $RootPath $SpaRelativeAppPath
$winLoginAppPath = Join-Path $RootPath $WinLoginRelativeAppPath
$mainAppPoolName = 'Series5-AppPool'
$spaHostName = 'local-series5'

# remove file permissions
$spaAclParams = @{
    SitePath        = $SitePhysicalPath
    AppPath         = $spaAppPath
    AppPoolIdentity = "IIS AppPool\$mainAppPoolName"
    ModifyPaths     = @('App_Data', 'Series5Seed\screens', 'UDFs', 'bin')
    ExecutePaths    = @('UDFs\PropertyBuilder.exe')
}
Remove-CaccaIISSiteAcl @spaAclParams
$winLoginAclParams = @{
    AppPath         = $winLoginAppPath
    AppPoolIdentity = "IIS AppPool\$mainAppPoolName"
    ModifyPaths     = @('App_Data')
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
Remove-TecBoxHostnames $spaHostName
Remove-TecBoxBackConnectionHostNames $spaHostName