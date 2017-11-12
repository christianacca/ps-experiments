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

        [switch] $PassThru
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        Import-Module IISSecurity -MinimumVersion '0.1.0' -MaximumVersion '0.1.999'        

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
        if (!$PSBoundParameters.ContainsKey('Commit')) {
            $Commit = $true
        }
    }
    
    process {
        try {
            
            $existingSite = Get-IISSite $Name;
            if ($existingSite -ne $null -and !$Force) {
                throw "Site already exists. To overwrite you must supply -Force"
            }

            if (-not(Test-Path $Path)) {
                if ($PSCmdlet.ShouldProcess($Path, 'Createing Website physical path')) {
                    New-Item $Path -ItemType Directory -WhatIf:$false | Out-Null
                }
            }

            if ($Commit) {
                Start-IISCommitDelay
            }

            try {

                if ($existingSite -ne $null) {
                    Remove-IISWebsite $Name -Commit:$false
                }
    
                New-IISAppPool $AppPoolName $AppPoolConfig -Commit:$false
    
                if ($PSCmdlet.ShouldProcess($Name, 'Creating Website')) {
                    $bindingInfo = "*:$($Port):$($HostName)"
                    [Microsoft.Web.Administration.Site] $site = New-IISSite $Name $Path $bindingInfo $Protocol -Passthru
                    $site.Applications["/"].ApplicationPoolName = $AppPoolName
                    $site | ForEach-Object $SiteConfig
                }
    
                if ($Commit) {
                    Stop-IISCommitDelay
                }
            }
            catch {
                if ($Commit) {
                    Stop-IISCommitDelay -Commit:$false
                }
                throw
            }
            finally {
                Reset-IISServerManager -Confirm:$false
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

            if ($PassThru -and $WhatIfPreference -eq $false) {
                Get-IISSite $Name
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}