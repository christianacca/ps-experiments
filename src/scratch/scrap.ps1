# setup
if ((Test-Path 'C:\Scrap\permissions')) {
    Remove-Item C:\Scrap\permissions -Force -Confirm:$false -Recurse
}
New-Item C:\Scrap\permissions\src\Ram.Series5.Spa -ItemType Directory
New-Item C:\Scrap\permissions\src\Ram.Series5.Spa\logs -ItemType Directory
New-Item C:\Scrap\permissions\src\Ram.Series5.Spa\bin -ItemType Directory
New-Item C:\Scrap\permissions\src\Ram.Series5.sln
New-Item C:\Scrap\permissions\src\Ram.Series5.Spa\Ram.Series5.Spa.csproj
New-Item C:\Scrap\permissions\src\Ram.Series5.Spa\bin\PropertyBuilder.exe


<#
# Hard-coded permission script
icacls C:\Scrap\permissions /grant:r '"BSW\Series5000Dev Group":(OI)(CI)F'
icacls C:\Scrap\permissions /inheritance:d 
icacls C:\Scrap\permissions /remove:g "NT AUTHORITY\Authenticated Users" /remove:d "NT AUTHORITY\Authenticated Users"
icacls C:\Scrap\permissions /remove:g BUILTIN\Users /remove:d BUILTIN\Users

icacls C:\Scrap\permissions\src\Ram.Series5.Spa /grant:r '"IIS AppPool\Series5-AppPool":(OI)(CI)R'
icacls C:\Scrap\permissions\src\Ram.Series5.Spa\logs /grant:r '"IIS AppPool\Series5-AppPool":(OI)(CI)M'
icacls C:\Scrap\permissions\src\Ram.Series5.Spa\bin\PropertyBuilder.exe /grant:r '"IIS AppPool\Series5-AppPool":(RX)'
#>

# variable script

$RootInstallPath = 'C:\Scrap\permissions'
$SiteAdminsGroup = 'BSW\Series5000Dev Group'
$AppPath = "$RootInstallPath\src\Ram.Series5.Spa"
$AppPoolName = 'Series5-AppPool'
$RelativePathsWithModifyPerms = @('logs')
$RelativePathsWithExecPerms = @('bin\PropertyBuilder.exe')


# make sure the right people can administer the web server (before we start removing permissions below)
icacls ("$RootInstallPath") /grant ("$SiteAdminsGroup" + ':(OI)(CI)F') # full permission, inheritted

# harden web server...
# 1. remove from as much of the file system as possible the groups that windows assigns to our AppPool Identity
icacls ("$RootInstallPath") /inheritance:d
$usersToRemove = 'NT AUTHORITY\Authenticated Users', 'BUILTIN\Users'
$usersToRemove | ForEach-Object {
    icacls ("$RootInstallPath") /remove:g ("$_") /remove:d ("$_")
}
# 2. add minimum permissions to AppPool identity
$appPoolIdentityName = "IIS AppPool\$AppPoolName"
icacls ("$AppPath") /grant:r ("$appPoolIdentityName" + ':(OI)(CI)R') # read, inheritted
$RelativePathsWithModifyPerms | ForEach-Object {
    icacls ("$AppPath\$_") /grant:r ("$appPoolIdentityName" + ':(OI)(CI)M') # modify, inheritted
}
$RelativePathsWithExecPerms | ForEach-Object {
    icacls ("$AppPath\$_") /grant:r ("$appPoolIdentityName" + ':(RX)') # read+execute
}

. .\src\iis-admin\Set-IISAppPoolIdentityAcl.ps1

$aclParams = @{
    RootPath = 'C:\Scrap\permissions'
    RelativeAppPath = 'src\Ram.Series5.Spa'
    AppPoolName = 'Series5-AppPool'
    RelativePathsWithModifyPerms = @('logs')
    RelativePathsWithExecPerms = @('bin\PropertyBuilder.exe')
    SiteAdminsGroup = 'BSW\Series5000Dev Group'
}
Set-IISAppPoolIdentityAcl @aclParams -Verbose