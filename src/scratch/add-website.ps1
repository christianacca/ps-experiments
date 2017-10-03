#Requires -RunAsAdministrator

param(
    [string]$RootPath = 'C:\Scrap\ps-websites',
    [string]$SiteName,
    [string]$AppName
)

[Microsoft.Web.Administration.ServerManager]$manager = Get-IISServerManager

$existingSite = $manager.Sites[$SiteName];
$existingPool = $manager.ApplicationPools[$AppName];
if ($existingPool -ne $null){
    $manager.ApplicationPools.Remove($existingPool)
}
if ($existingSite -ne $null) {
    $manager.Sites.Remove($existingSite)
}
$manager.CommitChanges()

$sitePath = Join-Path $RootPath $SiteName
$appPath = "$sitePath\$AppName"

New-Item $appPath -ItemType Directory -Force

$cred = Get-Credential
$pool = $manager.ApplicationPools.Add($AppName)
$pool.ManagedPipelineMode = "Integrated"
$pool.ManagedRuntimeVersion = "v4.0"
$pool.AutoStart = $true
$pool.ProcessModel.IdentityType = "SpecificUser"
$pool.ProcessModel.UserName = $cred.UserName
$pool.ProcessModel.Password = $cred.Password


$site = $manager.Sites.Add($SiteName, $sitePath, 8080)
$app = $site.Applications.Add("/$AppName", $appPath)
$app.ApplicationPoolName = $AppName

$manager.CommitChanges()