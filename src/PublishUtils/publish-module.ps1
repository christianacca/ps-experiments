$ErrorActionPreference = 'Stop'

$modulePath = Resolve-Path "$PSScriptRoot\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

$apiKey = Read-Host 'Enter NuGet Api Key'
if ([string]::IsNullOrWhiteSpace($apiKey)){
    return
}
$params = @{
    Repository = 'christianacca-ps'
    NuGetApiKey = $apiKey
    Path = "$PSScriptRoot\$moduleName"
}
Publish-Module @params
