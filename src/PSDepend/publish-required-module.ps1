param(
    [Parameter(Mandatory)] 
    [string] $NuGetApiKey
)
Publish-Module -Path "$PSScriptRoot\DemoRequiredModule" -NuGetApiKey $NuGetApiKey