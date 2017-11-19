#Requires -RunAsAdministrator

function Remove-IISWebsite {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {
            # note: this will produce a warning if site does not exist (this is the desire behaviour - no need to reproduce here)
            $siteInfo = Get-IISSiteHierarchyInfo $Name

            if (!$siteInfo) {
                return
            }

            Get-IISSiteAclPath $Name -Recurse | Where-Object IsShared -eq $false | Remove-CaccaUserFromAcl

            Start-IISCommitDelay
            try {
                Remove-IISSite $Name -Confirm:$false

                if ($WhatIfPreference -ne $true) {
                    # note: skipping errors when deleting app pool when that pool is shared by other sites
                    $siteInfo | Select-Object -Exp AppPool_Name -Unique | 
                        Remove-IISAppPool -EA Ignore -Commit:$false
                }

                Stop-IISCommitDelay     
            }
            catch {
                Stop-IISCommitDelay -Commit:$false
                throw
            }
            finally {
                Reset-IISServerManager -Confirm:$false -WhatIf:$false
            }

        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}