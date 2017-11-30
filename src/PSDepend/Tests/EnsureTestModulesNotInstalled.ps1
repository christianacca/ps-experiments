function EnsureTestModulesNotInstalled {
    Get-Module DemoRequiringModule -All | Remove-Module -Force
    Get-Module DemoRequiredModule -All | Remove-Module -Force
    Uninstall-Module DemoRequiringModule -AllVersions -EA SilentlyContinue -Force
    Uninstall-Module DemoRequiredModule -AllVersions -EA SilentlyContinue -Force
}