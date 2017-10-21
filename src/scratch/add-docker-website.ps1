#Requires -RunAsAdministrator

param(
    [string]$RootPath = 'C:\Scrap\ps-websites',

    [Parameter(Mandatory=$true)]
    [string]$SiteName,
    
    [Parameter(Mandatory=$true)]
    [string]$AppName
)

[Microsoft.Web.Administration.ServerManager]$manager = Get-IISServerManager

# todo-start: remove
$existingSite = $manager.Sites[$SiteName];
$existingPool = $manager.ApplicationPools[$AppName];
if ($existingPool -ne $null){
    $manager.ApplicationPools.Remove($existingPool)
}
if ($existingSite -ne $null) {
    $manager.Sites.Remove($existingSite)
}
$manager.CommitChanges()
# todo-end


$sitePath = Join-Path $RootPath $SiteName
$appPath = "$sitePath\$AppName"

# todo: remove
New-Item $appPath -ItemType Directory -Force

$pool = $manager.ApplicationPools.Add($AppName)
$pool.ManagedPipelineMode = "Integrated"
$pool.ManagedRuntimeVersion = "v4.0"
$pool.AutoStart = $true
$pool.ProcessModel.IdentityType = "ApplicationPoolIdentity"

# todo-start: remove
$pool.ProcessModel.IdentityType = "SpecificUser"
$cred = Get-Credential
$pool.ProcessModel.UserName = $cred.UserName
$pool.ProcessModel.Password = $cred.Password
# todo-end


$site = $manager.Sites.Add($SiteName, $sitePath, 8080)
$app = $site.Applications.Add("/$AppName", $appPath)
$app.ApplicationPoolName = $AppName

$manager.CommitChanges()