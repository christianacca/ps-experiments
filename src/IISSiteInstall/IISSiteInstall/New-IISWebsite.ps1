#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function New-IISWebsite {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

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

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $ModifyPaths,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $ExecutePaths,

        [switch] $SiteShellOnly,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $AppPoolName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [scriptblock] $AppPoolConfig,

        [switch] $Force
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        # Import-Module IISSecurity -MinimumVersion '0.1.0' -MaximumVersion '0.1.999'        

        if ([string]::IsNullOrWhiteSpace($Path)) {
            $Path = "C:\inetpub\sites\$Name"
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
            $AppPoolName = "$Name-AppPool"
        }
        if ($AppPoolConfig -eq $null) {
            $AppPoolConfig = {}
        }
    }
    
    process {
        try {
            
            $existingSite = Get-IISSite $Name -WA SilentlyContinue
            if ($existingSite -and !$Force) {
                throw "Site already exists. To overwrite you must supply -Force"
            }

            $isPathExists = Test-Path $Path
            if (!$isPathExists -and $PSCmdlet.ShouldProcess($Path, 'Create Web Site physical path')) {
                New-Item $Path -ItemType Directory -WhatIf:$false | Out-Null
            }

            if ($existingSite) {
                Remove-IISWebsite $Name -Confirm:$false
            }

            Start-IISCommitDelay

            try {
    
                New-IISAppPool $AppPoolName $AppPoolConfig -Force -Commit:$false | Out-Null
    
                if ($PSCmdlet.ShouldProcess($Name, 'Create Web Site')) {
                    $bindingInfo = "*:$($Port):$($HostName)"
                    [Microsoft.Web.Administration.Site] $site = New-IISSite $Name $Path $bindingInfo $Protocol -Passthru
                    $site.Applications["/"].ApplicationPoolName = $AppPoolName
                    $site | ForEach-Object $SiteConfig
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
                $siteAclParams = @{
                    SitePath      = $Path
                    AppPoolName   = $AppPoolName
                    ModifyPaths   = $ModifyPaths
                    ExecutePaths  = $ExecutePaths
                    SiteShellOnly = $SiteShellOnly
                }
                # note: we should NOT have to explicitly 'pass' WhatIfPreference (bug in PS?)
                Set-CaccaIISSiteAcl @siteAclParams -WhatIf:$WhatIfPreference
            }

            Get-IISSite $Name
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}