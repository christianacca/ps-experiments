$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'

Install-Script Publish-ScriptUrl -RequiredVersion '0.1.0'


$apiKey = Read-Host 'Enter NuGet Api Key'
if ([string]::IsNullOrWhiteSpace($apiKey)){
    return
}
$params = @{
    Repository = 'christianacca-ps'
    NuGetApiKey = $apiKey
    UrlPath = 'https://raw.githubusercontent.com/christianacca/Toolbox/ps-script-header/PowerShell'
}
Publish-ScriptUrl Add-Hostnames @params
Publish-ScriptUrl Remove-Hostnames @params
Publish-ScriptUrl Add-BackConnectionHostNames @params
Publish-ScriptUrl Remove-BackConnectionHostNames @params