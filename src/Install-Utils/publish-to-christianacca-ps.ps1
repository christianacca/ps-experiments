$ErrorActionPreference = 'Stop'

$apiKey = Read-Host 'Enter NuGet Api Key'
if ([string]::IsNullOrWhiteSpace($apiKey)){
    return
}
$params = @{
    Repository = 'christianacca-ps'
    NuGetApiKey = $apiKey
}
Publish-Module -Path '.\src\Install-Utils\Install-Utils' @params