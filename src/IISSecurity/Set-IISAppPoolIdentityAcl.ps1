function Set-IISAppPoolIdentityAcl {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $RootPath,

        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $RelativeAppPath,

        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $AppPoolName,

        [Parameter(ValueFromPipeline)]
        [string[]] $RelativePathsWithModifyPerms,

        [Parameter(ValueFromPipeline)]
        [string[]] $RelativePathsWithExecPerms,

        [Parameter(ValueFromPipeline)]
        [string] $SiteAdminsGroup
    )


    # make sure the right people can administer the web server (before we start removing permissions below)
    if (![string]::IsNullOrWhiteSpace($SiteAdminsGroup)) {
        if ($PSCmdlet.ShouldProcess($RootPath, "Granting '$SiteAdminsGroup' full permission (inherit)")) {
            icacls ("$RootPath") /grant ("$SiteAdminsGroup" + ':(OI)(CI)F') | Out-Null
        }
    }

    # harden web server ACL's...

    # 1. remove from file system the default groups that windows assigns to our AppPool Identity
    if ($PSCmdlet.ShouldProcess($RootPath, 'Disabling permission inheritance')) {
        icacls ("$RootPath") /inheritance:d | Out-Null
    }
    $usersToRemove = 'NT AUTHORITY\Authenticated Users', 'BUILTIN\Users'
    $usersToRemove | ForEach-Object {
        if ($PSCmdlet.ShouldProcess($RootPath, "Removing user '$_'")) {
            icacls ("$RootPath") /remove:g ("$_") /remove:d ("$_") | Out-Null
        }
    }

    # 2. add minimum permissions to AppPool identity
    $appPath = Join-Path $RootPath $RelativeAppPath
    $appPoolIdentityName = "IIS AppPool\$AppPoolName"
    if ($PSCmdlet.ShouldProcess($appPath, "Granting '$appPoolIdentityName' read permission (inherit)")) {
        icacls ("$appPath") /grant:r ("$appPoolIdentityName" + ':(OI)(CI)R') | Out-Null
    }
    $RelativePathsWithModifyPerms | ForEach-Object {
        $path = "$appPath\$_"
        if ($PSCmdlet.ShouldProcess($path, "Granting '$appPoolIdentityName' modify permission (inherit)")) {
            icacls ("$path") /grant:r ("$appPoolIdentityName" + ':(OI)(CI)M') | Out-Null
        }
        
    }
    $RelativePathsWithExecPerms | ForEach-Object {
        $path = "$appPath\$_"
        if ($PSCmdlet.ShouldProcess($path, "Granting '$appPoolIdentityName' read+execute permission")) {
            icacls ("$appPath\$_") /grant:r ("$appPoolIdentityName" + ':(RX)') | Out-Null
        }
    }
}