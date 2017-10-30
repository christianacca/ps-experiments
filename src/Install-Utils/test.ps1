#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Publish-Module -Path .\src\Install-Utils\Install-Utils -Repository LocalRepo

Uninstall-Module Install-Utils -EA 'SilentlyContinue'
Install-Module Install-Utils -Repository LocalRepo
Get-Module -Name Install-Utils -ListAvailable


Uninstall-Script Add-Hostnames -EA 'SilentlyContinue'
Uninstall-Module Publish-Utils -EA 'SilentlyContinue'

Install-CaccaMissingScript Add-Hostnames -Repository LocalRepo -Verbose
Install-CaccaMissingModule Publish-Utils -Repository LocalRepo -Verbose

Get-InstalledModule Publish-Utils
Get-InstalledScript Add-Hostnames


