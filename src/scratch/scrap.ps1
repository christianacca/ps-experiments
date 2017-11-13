Get-Module IISSiteInstall -All | Remove-Module
Import-Module .\src\IISSiteInstall\IISSiteInstall\IISSiteInstall.psd1

# Get-CaccaIISSiteHierarchyInfo

# New-CaccaIISWebsite FakeSite C:\inetpub\sites\FakeSite -Force

Reset-IISServerManager -Confirm:$false
Remove-CaccaIISWebSite Series5 -Confirm:$false

# Remove-CaccaIISWebsite Series5
# Reset-IISServerManager -Confirm:$false

# Remove-IISSite 'Crap'