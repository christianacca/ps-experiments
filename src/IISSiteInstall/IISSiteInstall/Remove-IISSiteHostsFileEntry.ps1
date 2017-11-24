#Requires -RunAsAdministrator

function Remove-IISSiteHostsFileEntry {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [PsCustomObject[]] $InputObject,

        [switch] $Force
        
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {

            $shared = $InputObject | Where-Object IsShared
            if ($shared -and !$Force) {
                throw "Cannot remove hostname(s) - one or more entries are shared by multiple sites"
            }

            $hostName = $InputObject | Select-Object -Exp Hostname -Unique
            # todo: add -WhatIf support to Remove-TecBoxHostnames
            if ($PSCmdlet.ShouldProcess($hostName, 'Remove hostname')) {
                $hostName | Remove-TecBoxHostnames
            }
            
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}