#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Import-Module IISAdministration

Publish-Module -Path .\src\Unlock-IISConfig\Unlock-IISConfig -Repository LocalRepo

Uninstall-Module Unlock-IISConfig -EA 'SilentlyContinue'
Install-Module Unlock-IISConfig -Repository LocalRepo
Get-Module -Name Unlock-IISConfig -ListAvailable
