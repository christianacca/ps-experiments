#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

$SiteName = 'Series5'

. .\src\scratch\Install-MissingScript.ps1

Install-MissingScript Add-Hostnames
Install-MissingScript Add-BackConnectionHostNames

# Declare script-wide constants/variables
$mainAppPoolName = 'Series5-AppPool'
$spaHostName = 'local-series5'

[Microsoft.Web.Administration.ServerManager]$manager = Get-IISServerManager

# Delete existing
Start-IISCommitDelay
$existingSite = $manager.Sites[$SiteName];
if ($existingSite -ne $null) {
    $manager.Sites.Remove($existingSite)
    Remove-Hostnames $spaHostName
    Remove-BackConnectionHostNames $spaHostName
}
$existingPool = $manager.ApplicationPools[$mainAppPoolName];
if ($existingPool -ne $null) {
    $manager.ApplicationPools.Remove($existingPool)
}
Stop-IISCommitDelay