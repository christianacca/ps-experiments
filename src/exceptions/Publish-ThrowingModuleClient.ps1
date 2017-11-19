$ErrorActionPreference = 'Stop'

$params = @{
    Repository = 'LocalRepo'
    Path = "$PSScriptRoot\ThrowingModuleClient"
}
Publish-Module @params
