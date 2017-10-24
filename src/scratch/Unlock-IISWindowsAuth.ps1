function Unlock-IISWindowsAuth {
    [CmdletBinding()]
    param (
        [string] $Location,
        [switch] $Minimum
    )
    
    begin {
        $callerEA = $ErrorActionPreference
    }
    
    process {
        try {
            $ErrorActionPreference = 'Stop'

            [Microsoft.Web.Administration.ServerManager]$mngr = Get-IISServerManager

            $winAuthConfig = Get-IISConfigSection `
                'system.webServer/security/authentication/windowsAuthentication' `
                -Location $Location

            $winAuthConfig.OverrideMode = 'Allow'
            if ($Minimum) {
                $winAuthConfig.SetMetadata('lockAllAttributesExcept', 'enabled')
                $winAuthConfig.SetMetadata('lockAllElementsExcept', 'extendedProtection')
            }

            $mngr.CommitChanges()
            
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}