function Set-IISAppPoolIdentityAcl {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $SitePath,

        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $AppPath,

        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $AppPoolName,

        [Parameter(ValueFromPipeline)]
        [string[]] $AppPathsWithModifyPerms,

        [Parameter(ValueFromPipeline)]
        [string[]] $AppPathsWithExecPerms
    )

    # add minimum permissions to AppPool identity

    $appPoolIdentityName = "IIS AppPool\$AppPoolName"

    if ([string]::IsNullOrWhiteSpace($SitePath)) {
        if ($PSCmdlet.ShouldProcess($SitePath, "Granting '$appPoolIdentityName' read permission to this folder and files (no inherit)")) {
            icacls ("$SiteRootPath") /grant:r ("$appPoolIdentityName" + ':(OI)(NP)R') | Out-Null
        }
    }

    $appFullPath = if ([string]::IsNullOrWhiteSpace($SitePath) -or [System.IO.Path]::IsPathRooted($AppPath)) {
        $AppPath
    } else {
        Join-Path $SitePath $AppPath
    }

    $getAppSubPath = {
        param([string] $SubPath)
        if ([System.IO.Path]::IsPathRooted($SubPath)) {
            $SubPath
        } else {
            Join-Path $appFullPath $SubPath
        }
    }

    if ($PSCmdlet.ShouldProcess($appFullPath, "Granting '$appPoolIdentityName' read permission (inherit)")) {
        icacls ("$appFullPath") /grant:r ("$appPoolIdentityName" + ':(OI)(CI)R') | Out-Null
    }
    $AppPathsWithModifyPerms | ForEach-Object {
        $subPath = & $getAppSubPath $_
        if ($PSCmdlet.ShouldProcess($path, "Granting '$appPoolIdentityName' modify permission (inherit)")) {
            icacls ("$subPath") /grant:r ("$appPoolIdentityName" + ':(OI)(CI)M') | Out-Null
        }
    }
    $AppPathsWithExecPerms | ForEach-Object {
        $subPath = & $getAppSubPath $_
        if ($PSCmdlet.ShouldProcess($subPath, "Granting '$appPoolIdentityName' read+execute permission")) {
            icacls ("$subPath") /grant:r ("$appPoolIdentityName" + ':(RX)') | Out-Null
        }
    }
}