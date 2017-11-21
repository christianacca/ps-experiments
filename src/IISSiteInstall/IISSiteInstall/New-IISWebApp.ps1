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
        [string] $AppPoolName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $AppPoolIdentity,

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

        $SiteName = $SiteName.Trim()
        $Name = $Name.Trim()

        if (!$Name.StartsWith('/')) {
            $Name = '/' + $Name
        }

        if ($ModifyPaths -eq $null) {
            $ModifyPaths = @()
        }
        if ($ExecutePaths -eq $null) {
            $ExecutePaths = @()
        }
    }
    
    process {
        try {
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
                if (-not(Get-IISAppPool $AppPoolName -WA SilentlyContinue)) {
                    New-IISAppPool $AppPoolName $AppPoolIdentity -Commit:$false | Out-Null
                }

                $pool = Get-IISAppPool $AppPoolName

                $AppPoolIdentity = $pool | Get-IISAppPoolUsername

                if ($AppPoolConfig) {
                    # note: assumed that 'AppPoolConfig' will NOT change the identity assigned to App Pool
                    $pool | ForEach-Object $AppPoolConfig | Out-Null
                }

                if ($PSCmdlet.ShouldProcess($qualifiedAppName, 'Create Web Application')) {
                    $app = $site.Applications.Add($Name, $childPath)
                    $app.ApplicationPoolName = $AppPoolName
                }

                Stop-IISCommitDelay
            }
            catch {
                Stop-IISCommitDelay -Commit:$false
                throw
            }
            finally {
                Reset-IISServerManager -Confirm:$false -WhatIf:$false
            }

            if ($WhatIfPreference -eq $true -and !$isPathExists) {
                # Set-CaccaIISSiteAcl requires path to exist
            }
            else {
                $appAclParams = @{
                    AppPath         = $childPath
                    AppPoolIdentity = $AppPoolIdentity
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