#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function New-IISWebApp {
    [CmdletBinding(SupportsShouldProcess)]
    param (
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Version 'Latest'
    }
    
    process {
        try {
            # todo
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }

    end {
    }
}