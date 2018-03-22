$ErrorActionPreference = 'Stop'

$publish = { Publish-Module -Path "$PSScriptRoot\ThrowingModule" -Repository LocalRepo }

try {
    Get-InstalledModule PreferenceVariables -EA Stop | Out-Null
    & $publish
}
catch {
    Install-Module PreferenceVariables
    & $publish
    Uninstall-Module PreferenceVariables
}