$ErrorActionPreference = 'Continue'

. "$PSScriptRoot\..\ThrowingFunctions\Get-MaybeThrow.ps1"
. "$PSScriptRoot\..\ThrowingFunctions\Get-MaybeThrowResult.ps1"

Get-MaybeThrowResult '?' -EA 'Continue'
Write-Host 'ThrowingModule.demo.ps1... still running (1)'

Get-MaybeThrowResult '?' -EA 'Stop'
Write-Host 'ThrowingModule.demo.ps1... still running (2)'