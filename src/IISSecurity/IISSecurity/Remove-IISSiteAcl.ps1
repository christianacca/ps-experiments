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

    .PARAMETER AppPoolIdentity
    The name of the User account whose permissions are to be removed

    .PARAMETER ModifyPaths
    Additional paths to remove permissions. Path(s) relative to AppPath can be supplied

    .PARAMETER ExecutePaths
    Additional paths to remove permissions. Path(s) relative to AppPath can be supplied

    .EXAMPLE
    Remove-IISSiteAcl -SitePath 'C:\inetpub\wwwroot' -AppPoolIdentity 'IIS AppPool\MyWebApp1-AppPool'

    Description
    -----------
    Remove AppPool Identity file permissions from a site

    .EXAMPLE
    Remove-IISSiteAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1' -AppPoolIdentity 'IIS AppPool\MyWebApp1-AppPool'

    Description
    -----------
    Remove AppPool Identity file permissions from site and a child web application

    .EXAMPLE
    Remove-IISSiteAcl -AppPath 'C:\Apps\MyWebApp1' -AppPoolIdentity 'mydomain\myuser' -ModifyPaths 'App_Data'

    Description
    -----------
    Remove AppPool Identity file permissions from a child web application only

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $AppPoolIdentity,

        [Parameter(ValueFromPipeline)]
        [ValidateScript({CheckPathExists $_})]
        [string] $SitePath,

        [Parameter(ValueFromPipeline)]
        [string] $AppPath,

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
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }

    process {
        try {

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

            $permissions | Remove-UserFromAcl -IdentityReference $AppPoolIdentity
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}