function Set-IISSiteAcl {
    <#
    .SYNOPSIS
    Set least privilege file/folder permissions to an IIS AppPool Useracount

    .DESCRIPTION
    Set least privilege file folder permissions on site and/or application file path
    to the useraccount that is configured as the identity of an IIS AppPool.

    These bare minium permissions include:
    - SitePath: Read 'This folder', and files (no inherit)
    - AppPath: Read 'This folder', file and subfolder permissions (inherited)
    - Temporary ASP.NET Files: Read 'This folder', file and subfolder permissions (inherited)
    - ModifyPaths: modify 'This folder', file and subfolder permissions (inherited)
    - ExecutePaths: read+execute file (no inherit)

    .PARAMETER SitePath
    The physical Website path. Omit this path when configuring the permissions of a child web application only

    .PARAMETER AppPath
    The physical Web application path. A path relative to SitePath can be supplied. Defaults to SitePath

    .PARAMETER AppPoolName
    The name of the AppPool that will be used to derive the User account to grant permissions for

    .PARAMETER AppPoolUsername
    The name of a specific User account whose permissions are to be granted

    .PARAMETER ModifyPaths
    Additional paths to grant modify (inherited) permissions. Path(s) relative to AppPath can be supplied

    .PARAMETER ExecutePaths
    Additional paths to grant read+excute permissions. Path(s) relative to AppPath can be supplied

    .EXAMPLE
    Set-IISSiteAcl -SitePath 'C:\inetpub\wwwroot' -AppPoolName 'MyWebApp1-AppPool'

    Description
    -----------
    Grant site file permissions to AppPoolIdentity

    .EXAMPLE
    Set-IISSiteAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1' -AppPoolName 'MyWebApp1-AppPool'

    Description
    -----------
    Grant site and chid application file permissions to AppPoolIdentity

    .EXAMPLE
    Set-IISSiteAcl -AppPath 'C:\Apps\MyWebApp1' -AppPoolUsername 'mydomain\myuser' -ModifyPaths 'App_Data'

    Description
    -----------
    Grant child application only file permissions to a specific user. Include folders that require modify permissions 

    #>    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline, Position = 1)]
        [ValidateScript( {CheckPathExists $_})]
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
        [string[]] $ModifyPaths = @(),
    
        [Parameter(ValueFromPipeline)]
        [ValidateNotNull()]
        [string[]] $ExecutePaths = @(),

        [switch] $SiteShellOnly
    )
    begin {
        Set-StrictMode -Version Latest
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        Write-Host "Set-IISSiteAcl:WhatIfPreference $WhatIfPreference"
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
                SitePath      = $SitePath
                AppPath       = $AppPath
                ModifyPaths   = $ModifyPaths
                ExecutePaths  = $ExecutePaths
                SiteShellOnly = $SiteShellOnly
            }
            $permissions = Get-IISSiteDesiredAcl @paths

            ValidateAclPaths $permissions 'Cannot grant permissions; missing paths detected'

            $permissions | ForEach-Object {
                if ($PSCmdlet.ShouldProcess($_.Path, "Granting '$appPoolIdentityName' $($_.Description)")) {
                    icacls ("$($_.Path)") /grant:r ("$appPoolIdentityName" + ':' + "$($_.Permission)") | Out-Null
                }
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}