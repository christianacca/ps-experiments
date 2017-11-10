Get-Module IISSiteInstall -All | Remove-Module
Import-Module .\src\IISSiteInstall\IISSiteInstall\IISSiteInstall.psd1

New-CaccaIISWebsite -SiteName Series10 -Path "$Env:TEMP\Series11" -Commit:$false
Get-IISSite Series10