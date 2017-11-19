#Requires -RunAsAdministrator

function Remove-UserFromAcl {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        $IdentityReference,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {

            if ($PSCmdlet.ShouldProcess($Path, "Removing '$IdentityReference'")) {
                
                # note: Where-Object we're ignoring errors. In essence we are skipping any user object
                # (IdentityReference) that can no longer be translated to a string, probably because it is "unknown"
                $acl = (Get-Item $_.Path).GetAccessControl('Access')
                $acl.Access | 
                    Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $IdentityReference } -EA Ignore |
                    ForEach-Object { $acl.RemoveAccessRuleAll($_) }
                Set-Acl -Path ($_.Path) -AclObject $acl
            }

        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}