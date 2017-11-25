#Requires -RunAsAdministrator

function New-IISWebApp {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $SiteName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(ValueFromPipelineByPropertyName)]
        [scriptblock] $Config,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $AppPoolName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [scriptblock] $AppPoolConfig,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $ModifyPaths,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $ExecutePaths,

        [switch] $Force
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        function GetAppPoolOtherAppCount {
            param (
                [string] $SiteName,
                [string] $ThisAppName,
                [string] $AppPoolName
            )
            Get-IISSiteHierarchyInfo | 
                Where-Object { $_.AppPool_Name -eq $AppPoolName -and $_.Site_Name -eq $SiteName -and $_.App_Path -ne $ThisAppName } |
                Select-Object App_Path -Unique |
                Measure-Object | Select-Object -Exp Count
        }
    }
    
    process {
        try {

            $SiteName = $SiteName.Trim()
            $Name = $Name.Trim()
            if (!$Name.StartsWith('/')) {
                $Name = '/' + $Name
            }
            if ($Config -eq $null) {
                $Config = {}
            }
            if ($ModifyPaths -eq $null) {
                $ModifyPaths = @()
            }
            if ($ExecutePaths -eq $null) {
                $ExecutePaths = @()
            }


            $site = Get-IISSite $SiteName
            if (!$site) {
                return
            }

            $qualifiedAppName = "$SiteName$Name"

            $existingApp = $site.Applications[$Name]
            if ($existingApp -and !$Force) {
                throw "Web Application '$qualifiedAppName' already exists. To overwrite you must supply -Force"
            }

            $rootApp = $site.Applications['/']
            if ([string]::IsNullOrWhiteSpace($AppPoolName)) {
                $AppPoolName = $rootApp.ApplicationPoolName
            }

            if ((GetAppPoolOtherSiteCount $SiteName $AppPoolName) -gt 0) {
                throw "Cannot create Web Application - AppPool '$AppPoolName' is in use on another site"
            }
            if ($AppPoolConfig -and (GetAppPoolOtherAppCount $SiteName $Name $AppPoolName) -gt 0) {
                throw "Cannot configure AppPool '$AppPoolName' - it belongs to another Web Application and/or this site"
            }

            $childPath = if ([string]::IsNullOrWhiteSpace($Path)) {
                $sitePath = $rootApp.VirtualDirectories['/'].PhysicalPath
                Join-Path $sitePath $Name
            }
            else {
                $Path
            }
            
            $isPathExists = Test-Path $childPath
            if (!$isPathExists -and $PSCmdlet.ShouldProcess($childPath, 'Create Web Application physical path')) {
                New-Item $childPath -ItemType Directory -WhatIf:$false | Out-Null
            }

            if ($existingApp) {
                Remove-IISWebApp $SiteName $Name -ModifyPaths $ModifyPaths -ExecutePaths $ExecutePaths
            }

            # Remove-IISWebApp has just committed changes making our $site instance read-only, therefore fetch another one
            $site = Get-IISSite $SiteName

            Start-IISCommitDelay
            try {
                $pool = Get-IISAppPool $AppPoolName -WA SilentlyContinue
                if (!$pool) {
                    $pool = New-IISAppPool $AppPoolName -Commit:$false
                }

                if ($AppPoolConfig -and $WhatIfPreference -eq $false) {
                    $pool | ForEach-Object $AppPoolConfig | Out-Null
                }

                if ($PSCmdlet.ShouldProcess($qualifiedAppName, 'Create Web Application')) {
                    $app = $site.Applications.Add($Name, $childPath)
                    $app.ApplicationPoolName = $AppPoolName

                    $app | ForEach-Object $Config
                }

                Stop-IISCommitDelay
            }
            catch {
                Stop-IISCommitDelay -Commit:$false
                throw
            }
            finally {
                Reset-IISServerManager -Confirm:$false
            }

            if ($WhatIfPreference -eq $true -and !$isPathExists) {
                # Set-CaccaIISSiteAcl requires path to exist
            }
            else {
                $appPoolIdentity = Get-IISAppPool $AppPoolName | Get-IISAppPoolUsername
                if ($WhatIfPreference -eq $true -and [string]::IsNullOrWhiteSpace($appPoolIdentity)) {
                    $appPoolIdentity = "IIS AppPool\$AppPoolName"
                }
                $appAclParams = @{
                    AppPath         = $childPath
                    AppPoolIdentity = $appPoolIdentity
                    ModifyPaths     = $ModifyPaths
                    ExecutePaths    = $ExecutePaths
                }
                Set-CaccaIISSiteAcl @appAclParams
            }

            (Get-IISSite $SiteName).Applications[$Name]
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}