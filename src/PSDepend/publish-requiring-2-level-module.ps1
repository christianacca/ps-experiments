param(
    [Parameter(Mandatory)]
    [string] $NuGetApiKey
)
begin {

    $installedModules = @()
    
    function InstallDependentModules {
        @('DemoRequiredModule', 'DemoRequiringExactModule') | % {
            if (-not( Get-InstalledModule $_ -EA SilentlyContinue)) {
                Install-Module $_
                $installedModules += $_
            }
        }
    }

    function UndoInstall {
        $installedModules | % { Uninstall-Module $_ }
    }
}
process {
    InstallDependentModules
    Publish-Module -Path "$PSScriptRoot\DemoRequiring2LevelModule" -NuGetApiKey $NuGetApiKey
    UndoInstall
}