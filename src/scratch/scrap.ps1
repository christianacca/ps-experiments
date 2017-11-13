Get-Module IISSiteInstall -All | Remove-Module
Import-Module .\src\IISSiteInstall\IISSiteInstall\IISSiteInstall.psd1

(Get-Item 'C:\Windows\Microsoft.NET\Framework\v2.0.50727\Temporary ASP.NET Files').GetAccessControl('Access').Access.IdentityReference | gm

Reset-IISServerManager -Confirm:$false
Remove-CaccaIISWebSite DeleteMeSite -WhatIf
