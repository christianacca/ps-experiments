$ErrorActionPreference = 'SilentlyContinue'

# Install-Module ThrowingModule -Repository LocalRepo
Import-Module ThrowingModule
# Get-Module ThrowingModule -All | Remove-Module -Force
# Import-Module "$PSScriptRoot\..\ThrowingModule"

Clear-Host

Get-CaccaMaybeThrowResult '?'
Write-Host 'ThrowingModule.demo.ps1... still running (1)'

try {
    Write-Host 'About to try and catch custom exception from Get-CaccaMaybeThrowResult'
    Get-CaccaMaybeThrowResult '?' -EA 'Stop'    
    Write-Host 'ThrowingModule.demo.ps1... still running (2)'
}
# catch [ThrowingModuleException] {
#     Write-Host 'Able to catch custom exception'
# }
catch {
    Write-Host 'Able to catch custom exception (kind of)'
}

Get-CaccaMaybeThrowResult '?' -EA 'Stop'
Write-Host 'ThrowingModule.demo.ps1... still running (3)'