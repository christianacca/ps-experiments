$ErrorActionPreference = 'Ignore'
$VerbosePreference = 'Continue'

# Uninstall-Module ThrowingModuleClient
# Uninstall-Module ThrowingModule

Install-Module PreferenceVariables
Install-Module ThrowingModuleClient -Repository LocalRepo
Import-Module ThrowingModuleClient


Set-CaccaMaybeThrowResult '?' -PassThru
Write-Host 'ThrowingModuleClient.demo.ps1... still running (1)'

Set-CaccaMaybeThrowResult '?' -PassThru -EA 'Stop' -Verbose
Write-Host 'ThrowingModuleClient.demo.ps1... still running (2)'