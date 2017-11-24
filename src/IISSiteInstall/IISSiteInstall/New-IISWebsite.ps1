#Requires -RunAsAdministrator

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

        [string] $HostsFileIPAddress,

        [switch] $Force
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {
            $Name = $Name.Trim()
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

            
            $existingSite = Get-IISSite $Name -WA SilentlyContinue
            if ($existingSite -and !$Force) {
                throw "Cannot create site - site '$Name' already exists. To overwrite you must supply -Force"
            }

            if ((GetAppPoolOtherSiteCount $Name $AppPoolName) -gt 0) {
                throw "Cannot create site - AppPool '$AppPoolName' is in use on another site"
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

                    $allHostNames = $site.Bindings | Select-Object -Exp Host -Unique
                    # todo: add -WhatIf support to Add-TecBoxHostnames
                    if (![string]::IsNullOrWhiteSpace($HostsFileIPAddress) -and ($PSCmdlet.ShouldProcess($allHostNames, 'Add hostname'))) {
                        $allHostNames | Add-TecBoxHostnames -IPAddress $HostsFileIPAddress
                    }
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
                $siteAclParams = @{
                    SitePath        = $Path
                    AppPoolIdentity = $appPoolIdentity
                    ModifyPaths     = $ModifyPaths
                    ExecutePaths    = $ExecutePaths
                    SiteShellOnly   = $SiteShellOnly
                }
                Set-CaccaIISSiteAcl @siteAclParams
            }

            Get-IISSite $Name
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}