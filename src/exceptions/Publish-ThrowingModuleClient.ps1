param()
begin {

    $ErrorActionPreference = 'Stop'

    $installedModules = @()
    
    function InstallDependentModules {
        @('PreferenceVariables', 'ThrowingModule') | % {
            if (-not( Get-InstalledModule $_ -EA SilentlyContinue)) {
                Install-Module $_
                $installedModules += $_
            }
        }
    }

    function UndoInstall {
        $installedModules | % { Uninstall-Module $_ -Force }
    }
}
process {
    InstallDependentModules
    Publish-Module -Path "$PSScriptRoot\ThrowingModuleClient" -Repository LocalRepo
    UndoInstall
}