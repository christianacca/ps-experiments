function Get-IISSiteDesiredAcl {
    <#
    .SYNOPSIS
    Returns the least privilege file/folder permissions that should be granted to an IIS AppPool useracount

    .DESCRIPTION
    Returns the least privilege file/folder permissions that should be granted to an IIS AppPool useracount

    .PARAMETER SitePath
    The physical Website path. Omit this path when configuring the permissions of a child web application only

    .PARAMETER AppPath
    The physical Web application path. A path relative to SitePath can be supplied. Defaults to SitePath

    .PARAMETER ModifyPaths
    Additional paths to remove permissions. Path(s) relative to AppPath can be supplied

    .PARAMETER ExecutePaths
    Additional paths to remove permissions. Path(s) relative to AppPath can be supplied

    .EXAMPLE
    Get-IISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot'

    Description
    -----------
    Return file permissions for a site

    .EXAMPLE
    Get-IISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1'

    Description
    -----------
    Return file permissions for a site and child web application

    .EXAMPLE
    Get-IISSiteDesiredAcl -AppPath 'C:\Apps\MyWebApp1' -ModifyPaths 'App_Data'

    Description
    -----------
    Return file permissions for a child web application only

    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
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

        [switch] $SkipTempAspNetFiles
    )
    begin {
        Set-StrictMode -Version Latest
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        function ToIcaclsPermission ([string] $Path, [string] $Permission, [string] $Description) {
            [PsCustomObject] @{
                Path        = $Path
                Permission  = $Permission
                Description = $Description
            }
        }

        function Add([System.Collections.Specialized.OrderedDictionary]$Results, [PSCustomObject] $Permission) {
            $key = Join-Path $Permission.Path '\'
            if ($Results.Contains($key)) {
                $original = $Results[$key]
                Write-Warning "Path '$($Permission.Path)' being assigned permissive rights; was: '$($original.Description)'; now: '$($Permission.Description)'"
            }
            $Results[$key] = $Permission
        }
    }

    process {
        try {
            if ([string]::IsNullOrWhiteSpace($SitePath) -and ![System.IO.Path]::IsPathRooted($AppPath)) {
                throw "AppPath must be a full path if SitePath is omitted"
            }

            if ([string]::IsNullOrWhiteSpace($SitePath) -and [string]::IsNullOrWhiteSpace($AppPath)) {
                throw "SitePath and/or AppPath must be supplied"
            }

            if ([string]::IsNullOrWhiteSpace($SitePath) -and $SiteShellOnly.IsPresent) {
                throw "SiteShellOnly must be used in conjunction with the SitePath parameter"
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

            $permissions = [ordered]@{}
            if ([string]::IsNullOrWhiteSpace($AppPath) -or $SitePath -eq $appFullPath) {
                # Site only...

                if ($SiteShellOnly) {
                    Add $permissions (ToIcaclsPermission $SitePath '(OI)(NP)R' 'read permission to this folder and files (no inherit)')
                }
                else {
                    Add $permissions (ToIcaclsPermission $appFullPath '(OI)(CI)R' 'read permission (inherit)')
                }                
            }
            elseif ([string]::IsNullOrWhiteSpace($SitePath)) {

                # App only...

                Add $permissions (ToIcaclsPermission $appFullPath '(OI)(CI)R' 'read permission (inherit)')
            }
            else {
                # Site and app...

                if ($PSBoundParameters.ContainsKey('SiteShellOnly') -and !$SiteShellOnly) {
                    Add $permissions (ToIcaclsPermission $SitePath '(OI)(CI)R' 'read permission (inherit)')
                }
                else {
                    Add $permissions (ToIcaclsPermission $SitePath '(OI)(NP)R' 'read permission to this folder and files (no inherit)')
                }
                Add $permissions (ToIcaclsPermission $appFullPath '(OI)(CI)R' 'read permission (inherit)')
            }
            $ModifyPaths | ForEach-Object $getAppSubPath | ForEach-Object {
                Add $permissions (ToIcaclsPermission $_ '(OI)(CI)M' 'modify permission (inherit)')
            }
            $ExecutePaths | ForEach-Object $getAppSubPath | ForEach-Object {
                Add $permissions (ToIcaclsPermission $_ '(RX)' 'read+execute permission')
            }
            if (!$SkipTempAspNetFiles) {
                Get-TempAspNetFilesPaths | ForEach-Object {
                    Add $permissions (ToIcaclsPermission $_ '(OI)(CI)R' 'read permission (inherit)')
                }
            }
            $permissions.Values
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}