function Unlock-IISWindowsAuth {
    [CmdletBinding()]
    param (
        [string] $Location,
        [switch] $Minimum,
        [switch] $Commit
    )
    
    begin {
        Set-StrictMode -Version Latest
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        if (!$PSBoundParameters.ContainsKey('Commit')) {
            $Commit = $true
        }
    }
    
    process {
        try {

            if ($Commit) {
                Start-IISCommitDelay
            }

            $winAuthConfig = Get-IISConfigSection `
                'system.webServer/security/authentication/windowsAuthentication' `
                -Location $Location

            $winAuthConfig.OverrideMode = 'Allow'
            if ($Minimum) {
                $winAuthConfig.SetMetadata('lockAllAttributesExcept', 'enabled')
                $winAuthConfig.SetMetadata('lockAllElementsExcept', 'extendedProtection')
            }

            if ($Commit) {
                Stop-IISCommitDelay
            }
            
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}