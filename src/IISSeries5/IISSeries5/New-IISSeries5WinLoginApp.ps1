function New-IISSeries5WinLoginApp {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $SiteSuffix,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $AppPath
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {

            $siteName = 'Series5'
            if (![string]::IsNullOrWhiteSpace($SiteSuffix)) {
                $siteName += "-$SiteSuffix"
            }

            $winLoginParams = @{
                SiteName = $siteName
                Name     = 'WinLogin'
                Path     = $AppPath
            }
            New-CaccaIISWebApp @winLoginParams -Config {
                Unlock-CaccaIISWindowsAuth -Location "$siteName$($_.Path)" -Minimum -Commit:$false
                Unlock-CaccaIISAnonymousAuth -Location "$siteName$($_.Path)" -Commit:$false
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}