<#
.SYNOPSIS
Set least privilege file/folder permissions to an IIS AppPool useracount

.DESCRIPTION
Set least privilege file folder permissions on site and/or application file path
to the useraccount that is configured as the identity of an IIS AppPool.

These bare minium permissions include:
- SitePath: Read 'This folder', and files (no inherit)
- AppPath: Read 'This folder', file and subfolder permissions (inherited)
- Temporary ASP.NET Files: Read 'This folder', file and subfolder permissions (inherited)
- AppPathsWithModifyPerms: modify 'This folder', file and subfolder permissions (inherited)
- AppPathsWithExecPerms: read+execute file (no inherit)

.PARAMETER SitePath
The physical website path (optional)

.PARAMETER AppPath
The physical Web application path. A relative path can be supplied, relative the SitePath supplied

.PARAMETER AppPoolName
The name of the AppPool that will be used to derive the useraccount to assign permissions for

.PARAMETER AppPoolUsername
The name of the useraccount to assign permissions for

.PARAMETER AppPathsWithModifyPerms
Additional paths to assign modify (inherited) permissions. Relative path(s) can be supplied, relative to AppPath

.PARAMETER AppPathsWithExecPerms
Additional paths to assign read+excute permissions. Relative path(s) can be supplied, relative to AppPath

.EXAMPLE
Example 1: Set minimum permissions to the AppPoolIdentity to a site and a child web application

Set-IISAppPoolIdentityAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1' -AppPoolName 'MyWebApp1-AppPool'

Example 2: Set web application only permissions to a specific user. Include folders that require modify permissions 

Set-IISAppPoolIdentityAcl -AppPath 'C:\Apps\MyWebApp1' -AppPoolUsername 'mydomain\myuser' -AppPathsWithModifyPerms 'App_Data'

#>
function Set-IISAppPoolIdentityAcl {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $SitePath,

        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $AppPath,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'AppPool')]
        [ValidateNotNullOrEmpty()]
        [string] $AppPoolName,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Username')]
        [ValidateNotNullOrEmpty()]
        [string] $AppPoolUsername,

        [Parameter(ValueFromPipeline)]
        [string[]] $AppPathsWithModifyPerms,

        [Parameter(ValueFromPipeline)]
        [string[]] $AppPathsWithExecPerms
    )
    begin {
        $callerEA = $ErrorActionPreference
    }

    process {
        try {
            # add minimum permissions to AppPool identity

            $appPoolIdentityName = if ($PSCmdlet.ParameterSetName -eq 'AppPool') {
                "IIS AppPool\$AppPoolName"
            }
            else { 
                $AppPoolUsername 
            }

            if (![string]::IsNullOrWhiteSpace($SitePath)) {
                if ($PSCmdlet.ShouldProcess($SitePath, "Granting '$appPoolIdentityName' read permission to this folder and files (no inherit)")) {
                    icacls ("$SitePath") /grant:r ("$appPoolIdentityName" + ':(OI)(NP)R') | Out-Null
                }
            }

            $appFullPath = if ([string]::IsNullOrWhiteSpace($SitePath) -or [System.IO.Path]::IsPathRooted($AppPath)) {
                $AppPath
            }
            else {
                Join-Path $SitePath $AppPath
            }

            $getAppSubPath = {
                param([string] $SubPath)
                if ([System.IO.Path]::IsPathRooted($SubPath)) {
                    $SubPath
                }
                else {
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

            $aspNetTempFolder = 'C:\Windows\Microsoft.NET\Framework*\v*\Temporary ASP.NET Files'
            Get-ChildItem $aspNetTempFolder | ForEach-Object {
                if ($PSCmdlet.ShouldProcess($_, "Granting '$appPoolIdentityName' read permission")) {
                    icacls ("$_") /grant:r ("$appPoolIdentityName" + ':(OI)(CI)R') | Out-Null
                }
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}