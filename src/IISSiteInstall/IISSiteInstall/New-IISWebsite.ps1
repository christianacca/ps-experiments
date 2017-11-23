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
        [PsCredential] $Credential,

        [Parameter(ValueFromPipelineByPropertyName)]
        [scriptblock] $AppPoolConfig,

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

            $appPoolIdentity = ''
            try {
    
                $appPoolIdentity = New-IISAppPool $AppPoolName $Credential $AppPoolConfig -Force -Commit:$false | 
                    Get-IISAppPoolUsername
    
                if ($PSCmdlet.ShouldProcess($Name, 'Create Web Site')) {
                    $bindingInfo = "*:$($Port):$($HostName)"
                    [Microsoft.Web.Administration.Site] $site = New-IISSite $Name $Path $bindingInfo $Protocol -Passthru
                    $site.Applications["/"].ApplicationPoolName = $AppPoolName

                    # note: assumed that 'SiteConfig' will NOT change the identity assigned to App Pool
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