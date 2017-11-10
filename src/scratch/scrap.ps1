Get-Module IISSiteInstall -All | Remove-Module
Import-Module .\src\IISSiteInstall\IISSiteInstall\IISSiteInstall.psd1

New-CaccaIISWebsite -SiteName Series10 -Path "Env:\TEMP" -WhatIf