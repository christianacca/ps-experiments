#Requires -Version 5.0 -Modules IISAdministration

function Unlock-IISAnonymousAuth {
    [CmdletBinding()]
    param (
        [string] $Location,
        [Microsoft.Web.Administration.ServerManager] $ServerManager
    )
    
    begin {
        $callerEA = $ErrorActionPreference
    }
    
    process {
        try {
            $ErrorActionPreference = 'Stop'

            Unlock-IISConfigSection `
                -SectionPath 'system.webServer/security/authentication/anonymousAuthentication' `
                -Location $Location `
                -ServerManager $ServerManager         
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}