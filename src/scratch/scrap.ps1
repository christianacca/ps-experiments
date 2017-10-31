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

New-Item C:\Scrap\permissions\src\Ram.Series5.WinLogin -ItemType Directory
New-Item C:\Scrap\permissions\src\Ram.Series5.WinLogin\logs -ItemType Directory
New-Item C:\Scrap\permissions\src\Ram.Series5.WinLogin\bin -ItemType Directory
New-Item C:\Scrap\permissions\src\Ram.Series5.WinLogin\Ram.Series5.WinLogin.csproj
return



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

. .\src\IISSecurity\Set-IISAppPoolIdentityAcl.ps1

$aclParams = @{
    RootPath = 'C:\Scrap\permissions'
    RelativeAppPath = 'src\Ram.Series5.Spa'
    AppPoolName = 'Series5-AppPool'
    RelativePathsWithModifyPerms = @('logs')
    RelativePathsWithExecPerms = @('bin\PropertyBuilder.exe')
    SiteAdminsGroup = 'BSW\Series5000Dev Group'
}
Set-IISAppPoolIdentityAcl @aclParams -Verbose

$aclWinLoginParams = @{
    RootPath = 'C:\Scrap\permissions\src\Ram.Series5.WinLogin'
    RelativeAppPath = '\'
    AppPoolName = 'Series5-AppPool'
    RelativePathsWithModifyPerms = @('logs')
}
Set-IISAppPoolIdentityAcl @aclWinLoginParams -Verbose