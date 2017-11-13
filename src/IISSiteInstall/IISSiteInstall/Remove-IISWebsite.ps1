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
            $siteInfo = Get-IISSiteHierarchyInfo $Name
            $permissions = Get-IISSiteAclPath $Name

            Start-IISCommitDelay
            try {
                if ($PSCmdlet.ShouldProcess($Name, 'Removing IIS Website')) {
                    Remove-IISSite $Name -Confirm:$false
                }

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

            $permissions | ForEach-Object {
                if ($PSCmdlet.ShouldProcess($_.Path, "Removing user '$($_.IdentityReference)'")) {

                    $id = $_.IdentityReference

                    $acl = (Get-Item $_.Path).GetAccessControl('Access')
                    $acl.Access | 
                        Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $id } |
                        ForEach-Object { $acl.RemoveAccessRuleAll($_) }
                    Set-Acl -Path ($_.Path) -AclObject $acl
                }
            }


        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}