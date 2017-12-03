Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

Write-Information '  Bootstrap dependencies'

if (-not (Get-PackageProvider -Name Nuget -EA SilentlyContinue))
{
    Write-Information '    Install Nuget PS package provider'
    Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
}

# register any custom repo's
# eg:
.\helpers\Register-PSRepositoryIfMissing christianacca-ps

$dendenciesPath = "$PSScriptRoot\dependencies"
if (-not(Test-Path "$dendenciesPath\PSDepend")) {
    New-Item $dendenciesPath -ItemType Directory | Out-Null
    # todo: remove `-Repository christianacca-ps` once changes are merged and deployed to PSGallery
    Save-Module -Name PSDepend -Path $dendenciesPath -Repository christianacca-ps
}

Write-Information '    Install And Import Dependent Modules'
Import-Module "$dendenciesPath\PSDepend"
Invoke-PSDepend "$PSScriptRoot\requirements.psd1" -Install -Import -Force -WarningAction SilentlyContinue