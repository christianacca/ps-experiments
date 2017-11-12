Get-Module IISSiteInstall -All | Remove-Module
Import-Module .\src\IISSiteInstall\IISSiteInstall\IISSiteInstall.psd1

Get-CaccaIISSiteHierarchyInfo

# New-CaccaIISWebsite FakeSite C:\inetpub\sites\FakeSite -AppPoolName 'Series5-AppPool' -Force

# Remove-CaccaIISWebsite Series5
# Reset-IISServerManager -Confirm:$false