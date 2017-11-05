<#
.SYNOPSIS
Remove the permissions that Set-IISAppPoolIdentityAcl assigns to the AppPool Identity

.DESCRIPTION
Remove the permissions that Set-IISAppPoolIdentityAcl assigns to the AppPool Identity

.PARAMETER SitePath
The physical Website path. Omit this path when configuring the permissions of a child web application only

.PARAMETER AppPath
The physical Web application path. A path relative to SitePath can be supplied. Defaults to SitePath

.PARAMETER AppPoolName
The name of the AppPool that will be used to derive the User account to remove permissions for

.PARAMETER AppPoolUsername
The name of a specific User account whose permissions are to be removed

.PARAMETER AppPathsWithModifyPerms
Additional paths to remove permissions. Path(s) relative to AppPath can be supplied

.PARAMETER AppPathsWithExecPerms
Additional paths to remove permissions. Path(s) relative to AppPath can be supplied

.EXAMPLE
Example 1: Remove AppPool Identity file permissions from a site

Remove-IISAppPoolIdentityAcl -SitePath 'C:\inetpub\wwwroot' -AppPoolName 'MyWebApp1-AppPool'

Example 2: Remove AppPool Identity file permissions from site and a child web application

Remove-IISAppPoolIdentityAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1' -AppPoolName 'MyWebApp1-AppPool'

Example 3: Remove AppPool Identity file permissions from a child web application only

Remove-IISAppPoolIdentityAcl -AppPath 'C:\Apps\MyWebApp1' -AppPoolUsername 'mydomain\myuser' -AppPathsWithModifyPerms 'App_Data'

#>
function Remove-IISAppPoolIdentityAcl {

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Username')]
    param(
        [Parameter(ValueFromPipeline, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path $_})]
        [string] $SitePath,

        [Parameter(ValueFromPipeline, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $AppPath,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'AppPool', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $AppPoolName,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Username', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $AppPoolUsername,

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
    }

    process {
        try {
            if ([string]::IsNullOrWhiteSpace($SitePath) -and ![System.IO.Path]::IsPathRooted($AppPath)) {
                throw "AppPath must be a full path if SitePath is omitted"
            }

            # ensure consistent trailing backslashs
            $SitePath = Join-Path $SitePath '\'

            $appPoolIdentityName = if ($PSCmdlet.ParameterSetName -eq 'AppPool') {
                "IIS AppPool\$AppPoolName"
            }
            else { 
                $AppPoolUsername 
            }

            $appFullPath = if ([string]::IsNullOrWhiteSpace($SitePath) -or (IsFullPath $AppPath)) {
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
            $targetPaths += $AppPathsWithExecPerms | ForEach-Object $getAppSubPath
            $targetPaths += $AppPathsWithModifyPerms | ForEach-Object $getAppSubPath
            if ($appFullPath -ne $SitePath) {
                $targetPaths += $appFullPath
            }
            if (![string]::IsNullOrWhiteSpace($SitePath)) {
                $targetPaths += $SitePath
            }
            $aspNetTempFolder = 'C:\Windows\Microsoft.NET\Framework*\v*\Temporary ASP.NET Files'
            $targetPaths += Get-ChildItem $aspNetTempFolder

            $targetPaths | Where-Object { -not(Test-Path $_) } -OutVariable missingPaths | ForEach-Object {
                Write-Warning "Path not found: '$_'"
            }
            if ($missingPaths) {
                throw "Cannot remove permissions; missing paths detected"
            }

            $targetPaths | ForEach-Object {
                if ($PSCmdlet.ShouldProcess($_, "Removing user '$appPoolIdentityName'")) {

                    $acl = (Get-Item $_).GetAccessControl('Access')
                    $acl.Access | 
                        Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $appPoolIdentityName } |
                        ForEach-Object { $acl.RemoveAccessRuleAll($_) }
                    Set-Acl -Path $_ -AclObject $acl
                }
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}