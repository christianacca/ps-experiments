. .\src\IISSecurity\Set-IISAppPoolIdentityAcl.ps1
. .\src\IISSecurity\Get-IISIcacls.ps1

# IsFullPath '\\'

Get-IISIcacls -SitePath 'C:\inetpub\sites\FakeSite'
Set-IISAppPoolIdentityAcl -SitePath 'C:\inetpub\sites\FakeSite' -AppPoolName 'Series5-AppPool'