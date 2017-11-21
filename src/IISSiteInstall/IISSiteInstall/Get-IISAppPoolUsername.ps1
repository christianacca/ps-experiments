#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function Get-IISAppPoolUsername {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Microsoft.Web.Administration.ApplicationPool] $InputObject
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {
            if ($InputObject.ProcessModel.IdentityType -eq 'ApplicationPoolIdentity') {
                "IIS AppPool\$($InputObject.Name)"
            } else {
                $InputObject.ProcessModel.UserName
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }

    end {
    }
}