#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function New-IISWebsite {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $SiteName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Path,

        [ValidateRange(0, 65535)]
        [int] $Port = 80,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Protocol = 'http',

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $HostName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [scriptblock] $SiteConfig,

        [Parameter(ValueFromPipeline)]
        [string[]] $ModifyPaths,

        [Parameter(ValueFromPipeline)]
        [string[]] $ExecutePaths,

        [switch] $SiteShellOnly,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $AppPoolName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [scriptblock] $AppPoolConfig,

        [switch] $Force,

        [switch] $PassThru,

        [Microsoft.Web.Administration.ServerManager] $ServerManager
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        Import-Module IISSecurity -MinimumVersion '0.1.0' -MaximumVersion '0.1.999'        

        if ([string]::IsNullOrWhiteSpace($Path)) {
            $Path = "C:\inetpub\sites\$SiteName"
        }
        if ($SiteConfig -eq $null) {
            $SiteConfig = {}
        }
        if ($ModifyPaths -eq $null) {
            $ModifyPaths = @()
        }
        if ($ExecutePaths -eq $null) {
            $ExecutePaths = @()
        }
        if ([string]::IsNullOrWhiteSpace($AppPoolName)) {
            $preferredName = if (![string]::IsNullOrWhiteSpace($HostName)) {
                $HostName
            }
            else {
                $SiteName
            }
            $AppPoolName = "$preferredName-AppPool"
        }
        if ($AppPoolConfig -eq $null) {
            $AppPoolConfig = {}
        }
        if (-not $ServerManager) {
            $ServerManager = Get-IISServerManager
            Start-IISCommitDelay
        }

        $isErrored = $false
    }
    
    process {
        try {
            
            $existingSite = $ServerManager.Sites[$SiteName];
            if ($existingSite -ne $null -and !$Force) {
                throw "Site already exists. To overwrite you must supply -Force"
            }

            if (-not(Test-Path $Path)) {
                if ($PSCmdlet.ShouldProcess($Path, 'Createing Website physical path')) {
                    New-Item $Path -ItemType Directory -WhatIf:$false | Out-Null
                }
            }            

            if ($existingSite -ne $null) {
                if ($PSCmdlet.ShouldProcess($SiteName, 'Deleting existing Website')) {
                    $ServerManager.Sites.Remove($existingSite)
                }
            }
            $existingPool = $ServerManager.ApplicationPools[$AppPoolName];
            if ($existingPool -ne $null) {
                if ($PSCmdlet.ShouldProcess($AppPoolName, 'Deleting existing App pool')) {
                    $ServerManager.ApplicationPools.Remove($existingPool)
                }
            }

            if ($PSCmdlet.ShouldProcess($AppPoolName, 'Creating App pool')) {
                $pool = $ServerManager.ApplicationPools.Add($AppPoolName)
                $pool.ManagedPipelineMode = "Integrated"
                $pool.ManagedRuntimeVersion = "v4.0"
                $pool.Enable32BitAppOnWin64 = $true # this IS the recommended default even for 64bit servers
                $pool.AutoStart = $true
                $pool | ForEach-Object $AppPoolConfig
            }

            if ($PSCmdlet.ShouldProcess($SiteName, 'Creating Website')) {
                $site = New-IISSite $SiteName $Path -BindingInformation "*:$($Port):$($HostName)" $Protocol -Passthru
                $site.Applications["/"].ApplicationPoolName = $AppPoolName
                $site | ForEach-Object $SiteConfig

                if ($PassThru) {
                    $site
                }
            }

            $siteAclParams = @{
                SitePath      = $Path
                AppPoolName   = $AppPoolName
                ModifyPaths   = $ModifyPaths
                ExecutePaths  = $ExecutePaths
                SiteShellOnly = $SiteShellOnly
            }
            # note: we should NOT have to explicitly 'pass' preference (bug in PS?)
            Set-CaccaIISSiteAcl @siteAclParams -WhatIf:$WhatIfPreference
            
        }
        catch {
            $isErrored = $true
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }

    end {
        if ($PSBoundParameters.ContainsKey('ServerManager')) {
            Stop-IISCommitDelay -Commit:(!$isErrored)
        }
    }
}