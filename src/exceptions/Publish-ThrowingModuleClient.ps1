$ErrorActionPreference = 'Stop'

Install-Module ThrowingModule -Repository LocalRepo

$params = @{
    Repository = 'LocalRepo'
    Path = "$PSScriptRoot\ThrowingModuleClient"
}
Publish-Module @params
