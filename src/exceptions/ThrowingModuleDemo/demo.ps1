$ErrorActionPreference = 'Stop'

Install-Module ThrowingModuleClient -Repository LocalRepo

Get-MaybeThrow '?' -EA 'Continue'
Write-Host 'demo.ps1... still running (1)'

Get-MaybeThrowResult '?' -EA 'Continue'
Write-Host 'demo.ps1... still running (2)'

Set-MaybeThrowResult '?' -PassThru -EA 'Continue'
Write-Host 'demo.ps1... still running (3)'