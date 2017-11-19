$ErrorActionPreference = 'Stop'

$params = @{
    Repository = 'LocalRepo'
    Path = "$PSScriptRoot\ThrowingModule"
}
Publish-Module @params
