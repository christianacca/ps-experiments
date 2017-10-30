#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Publish-Module -Path .\src\Publish-Utils\Publish-Utils -Repository LocalRepo

Uninstall-Module Publish-Utils -EA 'SilentlyContinue'
Install-Module Publish-Utils -Repository LocalRepo
Get-Module -Name Publish-Utils -ListAvailable

$params = @{
    Repository = 'LocalRepo'
    UrlPath = 'https://raw.githubusercontent.com/christianacca/Toolbox/ps-script-header/PowerShell'
}
Publish-CaccaScriptUrl Add-Hostnames @params

$adhocScriptParams = @{
    Repository = 'LocalRepo'
    UrlPath = 'https://raw.githubusercontent.com/jeremy-jameson/Toolbox/master/PowerShell'
    Author = 'christianacca'
    Version = '1.0.1'
}
Publish-CaccaAdhocScriptUrl Add-BackConnectionHostNames @adhocScriptParams


