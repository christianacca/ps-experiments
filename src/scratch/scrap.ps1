Set-Location C:\Git\ps-experiments\

. .\src\IISSecurity\IISSecurity\Get-IISSiteDesiredAcl.ps1

Get-IISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -EA Stop

