$ErrorActionPreference = 'Continue'

Install-Module ThrowingModule -Repository LocalRepo
Import-Module ThrowingModule
# Get-Module ThrowingModule -All | Remove-Module -Force
# Import-Module "$PSScriptRoot\..\ThrowingModule"

Get-CaccaMaybeThrowResult '?' -EA 'Continue'
Write-Host 'ThrowingModule.demo.ps1... still running (1)'

Get-CaccaMaybeThrowResult '?' -EA 'Stop'
Write-Host 'ThrowingModule.demo.ps1... still running (2)'