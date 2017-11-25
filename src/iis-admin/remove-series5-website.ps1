#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Import-Module '.\src\IISSiteInstall\IISSiteInstall\IISSiteInstall.psd1'

Remove-CaccaIISWebsite 'Series5'