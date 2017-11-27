function New-IISSeries5Spa {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $CompanyName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $SitePath,

        [ValidateRange(0, 65535)]
        [int] $Port = 80,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $AppPath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $WinLoginAppPath,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $HostName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $LocalDns
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {

            if (!$PSBoundParameters.ContainsKey('LocalDns') -and ![string]::IsNullOrWhiteSpace($HostName)) {
                $LocalDns = $true
            }


            $siteName = 'Series5'
            if (![string]::IsNullOrWhiteSpace($CompanyName)) {
                $siteName += "-$CompanyName"
            }
            $siteShellOnly = ![string]::IsNullOrWhiteSpace($AppPath)

            $siteParams = @{
                Name                     = $siteName
                Path                     = $SitePath
                Port                     = $Port
                HostName                 = $HostName
                SiteShellOnly            = $siteShellOnly
                HostsFileIPAddress       = if ($LocalDns) { '127.0.0.1' } else { $null }
                AddHostToBackConnections = $LocalDns
            }
            New-CaccaIISWebsite @siteParams -Force

            # Create SPA child application
            $spaParams = @{
                SiteName     = $siteName
                Name         = 'Spa'
                Path         = $AppPath
                ModifyPaths  = @('App_Data', 'Series5Seed\screens', 'UDFs', 'bin')
                ExecutePaths = @('UDFs\PropertyBuilder.exe')
            }
            New-CaccaIISWebApp @spaParams -Config {
                Unlock-CaccaIISAnonymousAuth -Location "$siteName$($_.Path)" -Commit:$false
                Unlock-CaccaIISConfigSection -SectionPath 'system.webServer/rewrite/allowedServerVariables' -Location "$siteName$($_.Path)" -Commit:$false    
            }

            if (![string]::IsNullOrWhiteSpace($WinLoginAppPath)) {
                New-IISSeries5WinLoginApp $CompanyName $WinLoginAppPath
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}