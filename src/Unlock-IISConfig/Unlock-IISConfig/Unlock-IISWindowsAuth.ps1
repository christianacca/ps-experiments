#Requires -Version 5.0 -Modules IISAdministration

function Unlock-IISWindowsAuth {
    [CmdletBinding()]
    param (
        [string] $Location,
        [switch] $Minimum,
        [Microsoft.Web.Administration.ServerManager] $ServerManager
    )
    
    begin {
        $callerEA = $ErrorActionPreference
    }
    
    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $ServerManager) {
                $ServerManager = Get-IISServerManager
            }

            $winAuthConfig = Get-IISConfigSection `
                'system.webServer/security/authentication/windowsAuthentication' `
                -Location $Location

            $winAuthConfig.OverrideMode = 'Allow'
            if ($Minimum) {
                $winAuthConfig.SetMetadata('lockAllAttributesExcept', 'enabled')
                $winAuthConfig.SetMetadata('lockAllElementsExcept', 'extendedProtection')
            }

            if (-not $PSBoundParameters.ContainsKey('ServerManager')) {
                $ServerManager.CommitChanges()
            }
            
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}