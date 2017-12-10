function Get-FromRequiredModule {
    [CmdletBinding()]
    param (
        [string] $Value
    )
    
    begin {
        $ErrorActionPreference = 'Stop'
    }
    
    process {

        Get-CaccaRequired $Value -EA 'Stop'
    }
}