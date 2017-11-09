#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

function New-IISWebApp {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {
            # todo
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}