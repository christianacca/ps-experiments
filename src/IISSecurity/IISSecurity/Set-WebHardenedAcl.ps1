function Set-WebHardenedAcl {
    <#
    .SYNOPSIS
    Remove default user and group file permissions added by windows

    .DESCRIPTION
    Remove from 'Path' supplied, the default user and group file permissions added by windows

    Users/groups file permissions removed:
    * Authenticated Users
    * Users
    * IIS_IUSRS
    * NETWORK SERVICE

    .PARAMETER Path
    The path to target permission removal

    .PARAMETER SiteAdminsGroup
    Optional user/group name to assign full permissions (inherited) to 'Path'

    .EXAMPLE
    Set-CaccaWebHardenedAcl -Path C:\inetpub -SiteAdminsGroup 'mydomain\mygroup'

    .NOTES
    This script must be run with administrator privileges.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {CheckPathExists $_})]
        [string] $Path,
        
        [Parameter(ValueFromPipeline)]
        [string] $SiteAdminsGroup
    )

    begin {
        Set-StrictMode -Version Latest
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }

    process {
        try {

            # make sure the right people can administer the web server (before we start removing permissions below)
            if (![string]::IsNullOrWhiteSpace($SiteAdminsGroup)) {
                if ($PSCmdlet.ShouldProcess($Path, "Granting '$SiteAdminsGroup' full permission (inherit)")) {
                    icacls ("$Path") /grant ("$SiteAdminsGroup" + ':(OI)(CI)F') | Out-Null
                }
            }

            # harden web server ACL's...
            
            $usersToRemove = 'NT AUTHORITY\Authenticated Users', 'BUILTIN\Users', 'BUILTIN\IIS_IUSRS', 'NT AUTHORITY\NETWORK SERVICE'

            if ($PSCmdlet.ShouldProcess($Path, 'Disabling permission inheritance')) {
                icacls ("$Path") /inheritance:d | Out-Null
            }
            $usersToRemove | ForEach-Object {
                if ($PSCmdlet.ShouldProcess($Path, "Removing user '$_'")) {
                    icacls ("$Path") /remove:g ("$_") /remove:d ("$_") | Out-Null
                }
            }       
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}