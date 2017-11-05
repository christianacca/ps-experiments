<#
.SYNOPSIS
Returns the least privilege file/folder permissions that should be granted to an IIS AppPool useracount

.DESCRIPTION
Returns the least privilege file/folder permissions that should be granted to an IIS AppPool useracount

.PARAMETER SitePath
The physical Website path. Omit this path when configuring the permissions of a child web application only

.PARAMETER AppPath
The physical Web application path. A path relative to SitePath can be supplied. Defaults to SitePath

.PARAMETER AppPathsWithModifyPerms
Additional paths to remove permissions. Path(s) relative to AppPath can be supplied

.PARAMETER AppPathsWithExecPerms
Additional paths to remove permissions. Path(s) relative to AppPath can be supplied

.EXAMPLE
Example 1: Return file permissions for a site

Get-IISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot'

Example 2: Return file permissions for a site and child web application

Get-IISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1'

Example 3: Return file permissions for a child web application only

Get-IISSiteDesiredAcl -AppPath 'C:\Apps\MyWebApp1' -AppPathsWithModifyPerms 'App_Data'

#>
function Get-IISSiteDesiredAcl {

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string] $SitePath,

        [Parameter(ValueFromPipeline)]
        [string] $AppPath,

        [Parameter(ValueFromPipeline)]
        [ValidateNotNull()]
        [string[]] $AppPathsWithModifyPerms = @(),

        [Parameter(ValueFromPipeline)]
        [ValidateNotNull()]
        [string[]] $AppPathsWithExecPerms = @()
    )
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        function ToIcaclsPermission ([string] $Path, [string] $Permission, [string] $Description) {
            [PsCustomObject] @{
                Path        = $Path
                Permission  = $Permission
                Description = $Description
            }
        }
    }

    process {
        try {
            if ([string]::IsNullOrWhiteSpace($SitePath) -and ![System.IO.Path]::IsPathRooted($AppPath)) {
                throw "AppPath must be a full path if SitePath is omitted"
            }

            # ensure consistent trailing backslashs
            if (![string]::IsNullOrWhiteSpace($SitePath)) {
                $SitePath = Join-Path $SitePath '\'
            }
            if (![string]::IsNullOrWhiteSpace($AppPath)) {
                $AppPath = Join-Path $AppPath '\'
            }

            $appFullPath = if ([string]::IsNullOrWhiteSpace($SitePath) -or [System.IO.Path]::IsPathRooted($AppPath)) {
                $AppPath
            }
            else {
                Join-Path $SitePath $AppPath
            }

            $getAppSubPath = {
                if ([System.IO.Path]::IsPathRooted($_)) {
                    $_
                }
                else {
                    Join-Path $appFullPath $_
                }
            }

            $targetPaths = @()
            if (![string]::IsNullOrWhiteSpace($SitePath) -and $appFullPath -ne $SitePath) {
                ToIcaclsPermission $SitePath '(OI)(NP)R' 'read permission to this folder and files (no inherit)'
            }
            ToIcaclsPermission $appFullPath '(OI)(CI)R' 'read permission (inherit)'
            $AppPathsWithModifyPerms | ForEach-Object $getAppSubPath | ForEach-Object {
                ToIcaclsPermission $_ '(OI)(CI)M' 'modify permission (inherit)'
            }
            $AppPathsWithExecPerms | ForEach-Object $getAppSubPath | ForEach-Object {
                ToIcaclsPermission $_ '(RX)' 'read+execute permission'
            }
            $aspNetTempFolder = 'C:\Windows\Microsoft.NET\Framework*\v*\Temporary ASP.NET Files'
            Get-ChildItem $aspNetTempFolder | Select-Object -Exp FullName | ForEach-Object {
                ToIcaclsPermission $_ '(OI)(CI)R' 'read permission (inherit)'
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}