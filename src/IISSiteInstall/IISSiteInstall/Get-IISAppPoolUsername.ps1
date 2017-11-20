#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function Get-IISAppPoolUsername {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [Microsoft.Web.Administration.ApplicationPool] $AppPool
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {
            if ($AppPool.ProcessModel.IdentityType -eq 'ApplicationPoolIdentity') {
                "IIS AppPool\$($AppPool.Name)"
            } else {
                $AppPool.ProcessModel.UserName
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }

    end {
    }
}