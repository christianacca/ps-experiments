function Get-FromRequiringExactModule {
    [CmdletBinding()]
    param (
        [string] $Value
    )
    
    begin {
        $ErrorActionPreference = 'Stop'
    }
    
    process {

        Get-FromRequiredModule $Value -EA 'Stop'
    }
}