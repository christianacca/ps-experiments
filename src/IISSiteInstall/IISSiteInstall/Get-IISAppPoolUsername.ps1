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

            switch ($InputObject.ProcessModel.IdentityType) {
                'ApplicationPoolIdentity' { 
                    "IIS AppPool\$($InputObject.Name)"
                }
                'NetworkService' { 
                    'NT AUTHORITY\NETWORK SERVICE'
                }
                'LocalSystem' { 
                    'NT AUTHORITY\SYSTEM'
                }
                'LocalService' { 
                    'NT AUTHORITY\LOCAL SERVICE'
                }
                Default {
                    $InputObject.ProcessModel.UserName
                }
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }

    end {
    }
}