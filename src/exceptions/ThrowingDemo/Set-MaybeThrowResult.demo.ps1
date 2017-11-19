$ErrorActionPreference = 'Continue'

. "$PSScriptRoot\..\ThrowingFunctions\Get-MaybeThrow.ps1"
. "$PSScriptRoot\..\ThrowingFunctions\Get-MaybeThrowResult.ps1"
. "$PSScriptRoot\..\ThrowingFunctions\Set-MaybeThrowResult.ps1"


Set-MaybeThrowResult '?' -PassThru -EA 'Continue' -Verbose
Write-Host 'ThrowingModuleClient.demo.ps1... still running (1)'

Set-MaybeThrowResult '?' -PassThru -EA 'Stop' -Verbose
Write-Host 'ThrowingModuleClient.demo.ps1... still running (2)'