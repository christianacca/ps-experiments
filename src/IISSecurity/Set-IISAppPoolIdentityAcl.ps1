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
The physical Website path. Omit this path when configuring the permissions of a child web application only

.PARAMETER AppPath
The physical Web application path. A path relative to SitePath can be supplied. Defaults to SitePath

.PARAMETER AppPoolName
The name of the AppPool that will be used to derive the User account to assign permissions for

.PARAMETER AppPoolUsername
The name of a specific User account whose permissions are to be assigned

.PARAMETER AppPathsWithModifyPerms
Additional paths to assign modify (inherited) permissions. Path(s) relative to AppPath can be supplied

.PARAMETER AppPathsWithExecPerms
Additional paths to assign read+excute permissions. Path(s) relative to AppPath can be supplied

.EXAMPLE
Example 1: Grant permissions to the AppPoolIdentity of a site

Set-IISAppPoolIdentityAcl -SitePath 'C:\inetpub\wwwroot' -AppPoolName 'MyWebApp1-AppPool'

Example 2: Grant permissions to the AppPoolIdentity to a site and a child web application

Set-IISAppPoolIdentityAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1' -AppPoolName 'MyWebApp1-AppPool'

Example 3: Set web application only permissions to a specific user. Include folders that require modify permissions 

Set-IISAppPoolIdentityAcl -AppPath 'C:\Apps\MyWebApp1' -AppPoolUsername 'mydomain\myuser' -AppPathsWithModifyPerms 'App_Data'

#>
function Set-IISAppPoolIdentityAcl {
    
    [CmdletBinding(SupportsShouldProcess)]
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
            
            if (![string]::IsNullOrWhiteSpace($SitePath) -and $appFullPath -ne $SitePath) {
                if ($PSCmdlet.ShouldProcess($SitePath, "Granting '$appPoolIdentityName' read permission to this folder and files (no inherit)")) {
                    icacls ("$SitePath") /grant:r ("$appPoolIdentityName" + ':(OI)(NP)R') | Out-Null
                }
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
                $appSubPath = & $getAppSubPath $_
                if ($PSCmdlet.ShouldProcess($appSubPath, "Granting '$appPoolIdentityName' modify permission (inherit)")) {
                    icacls ("$appSubPath") /grant:r ("$appPoolIdentityName" + ':(OI)(CI)M') | Out-Null
                }
            }
    
            $AppPathsWithExecPerms | ForEach-Object {
                $appSubPath = & $getAppSubPath $_
                if ($PSCmdlet.ShouldProcess($appSubPath, "Granting '$appPoolIdentityName' read+execute permission")) {
                    icacls ("$appSubPath") /grant:r ("$appPoolIdentityName" + ':(RX)') | Out-Null
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