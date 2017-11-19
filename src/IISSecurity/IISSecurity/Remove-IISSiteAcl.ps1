function Remove-IISSiteAcl {
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

    .PARAMETER ModifyPaths
    Additional paths to remove permissions. Path(s) relative to AppPath can be supplied

    .PARAMETER ExecutePaths
    Additional paths to remove permissions. Path(s) relative to AppPath can be supplied

    .EXAMPLE
    Remove-IISSiteAcl -SitePath 'C:\inetpub\wwwroot' -AppPoolName 'MyWebApp1-AppPool'

    Description
    -----------
    Remove AppPool Identity file permissions from a site

    .EXAMPLE
    Remove-IISSiteAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1' -AppPoolName 'MyWebApp1-AppPool'

    Description
    -----------
    Remove AppPool Identity file permissions from site and a child web application

    .EXAMPLE
    Remove-IISSiteAcl -AppPath 'C:\Apps\MyWebApp1' -AppPoolUsername 'mydomain\myuser' -ModifyPaths 'App_Data'

    Description
    -----------
    Remove AppPool Identity file permissions from a child web application only

    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Username')]
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
        
        [switch] $SiteShellOnly,
        
        [switch] $SkipMissingPaths,

        [switch] $SkipTempAspNetFiles
    )
    begin {
        Set-StrictMode -Version Latest
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
                SitePath            = $SitePath
                AppPath             = $AppPath
                ModifyPaths         = $ModifyPaths
                ExecutePaths        = $ExecutePaths
                SiteShellOnly       = $SiteShellOnly
                SkipTempAspNetFiles = $SkipTempAspNetFiles
            }
            $permissions = Get-IISSiteDesiredAcl @paths | Where-Object { $SkipMissingPaths -eq $false -or (Test-Path $_.Path) }

            ValidateAclPaths $permissions 'Cannot remove permissions; missing paths detected'

            $permissions | Remove-UserFromAcl -IdentityReference $appPoolIdentityName
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}