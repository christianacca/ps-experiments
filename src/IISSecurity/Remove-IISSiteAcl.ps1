<#
.SYNOPSIS
Remove the permissions that Set-IISSiteAcl grants to the AppPool Identity

.DESCRIPTION
Remove the permissions that Set-IISSiteAcl grants to the AppPool Identity

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

Remove-IISSiteAcl -SitePath 'C:\inetpub\wwwroot' -AppPoolName 'MyWebApp1-AppPool'

Example 2: Remove AppPool Identity file permissions from site and a child web application

Remove-IISSiteAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1' -AppPoolName 'MyWebApp1-AppPool'

Example 3: Remove AppPool Identity file permissions from a child web application only

Remove-IISSiteAcl -AppPath 'C:\Apps\MyWebApp1' -AppPoolUsername 'mydomain\myuser' -AppPathsWithModifyPerms 'App_Data'

#>
function Remove-IISSiteAcl {

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Username')]
    param(
        [Parameter(ValueFromPipeline, Position = 1)]
        [ValidateScript( { Test-Path $_})]
        [string] $SitePath,

        [Parameter(ValueFromPipeline, Position = 2)]
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

            $appPoolIdentityName = if ($PSCmdlet.ParameterSetName -eq 'AppPool') {
                "IIS AppPool\$AppPoolName"
            }
            else { 
                $AppPoolUsername 
            }

            $paths = @{
                SitePath                = $SitePath
                AppPath                 = $AppPath
                AppPathsWithModifyPerms = $AppPathsWithModifyPerms
                AppPathsWithExecPerms   = $AppPathsWithExecPerms
            }
            $permissions = Get-IISIcacls @paths

            ValidateAclPaths $permissions 'Cannot remove permissions; missing paths detected'

            $permissions | ForEach-Object {
                if ($PSCmdlet.ShouldProcess($_.Path, "Removing user '$appPoolIdentityName'")) {

                    $acl = (Get-Item $_.Path).GetAccessControl('Access')
                    $acl.Access | 
                        Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $appPoolIdentityName } |
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