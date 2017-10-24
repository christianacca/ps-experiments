. .\src\scratch\Unlock-IISWindowsAuth.ps1
. .\src\scratch\Unlock-IISAnonymousAuth.ps1
. .\src\scratch\Unlock-IISConfigSection.ps1

Start-IISCommitDelay

Unlock-IISWindowsAuth -Location 'Default Web Site/Ram.Series5.Spa' -Minimum
Unlock-IISAnonymousAuth -Location 'Default Web Site/Ram.Series5.Spa'
Unlock-IISConfigSection -SectionPath 'system.webServer/rewrite/allowedServerVariables' -Location 'Default Web Site/Ram.Series5.Spa'
Stop-IISCommitDelay