function Set-WebHardenedAcl {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,
        
        [Parameter(ValueFromPipeline)]
        [string] $SiteAdminsGroup
    )

    # make sure the right people can administer the web server (before we start removing permissions below)
    if (![string]::IsNullOrWhiteSpace($SiteAdminsGroup)) {
        if ($PSCmdlet.ShouldProcess($Path, "Granting '$SiteAdminsGroup' full permission (inherit)")) {
            icacls ("$Path") /grant ("$SiteAdminsGroup" + ':(OI)(CI)F') | Out-Null
        }
    }

    # harden web server ACL's...

    # remove from file system the default groups that windows assigns to AppPool Identity and shared service accoumts

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