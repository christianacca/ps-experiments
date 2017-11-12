#Requires -RunAsAdministrator

function Remove-IISWebsite {
    [CmdletBinding(SupportsShouldProcess)]
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
            $siteInfo = Get-IISSiteHierarchyInfo $Name

            Start-IISCommitDelay
            try {
                if ($PSCmdlet.ShouldProcess($Name, 'Removing IIS Website')) {
                    Remove-IISSite $Name -Confirm:$false
                }

                if ($PSCmdlet.ShouldProcess($Name, 'Removing (non-shared) App pool(s)')) {
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