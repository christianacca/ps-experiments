param(
    [Parameter(Mandatory)]
    [string] $NuGetApiKey
)

$publish = { Publish-Module -Path "$PSScriptRoot\DemoRequiringModule" -NuGetApiKey $NuGetApiKey }

try {
    Get-InstalledModule DemoRequiredModule -EA Stop
    & $publish
}
catch {
    Install-Module DemoRequiredModule
    & $publish
    Uninstall-Module DemoRequiringModule
}