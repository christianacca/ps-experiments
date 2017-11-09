#Requires -Version 5.0 -Modules IISAdministration

function Unlock-IISAnonymousAuth {
    [CmdletBinding()]
    param (
        [string] $Location,
        [Microsoft.Web.Administration.ServerManager] $ServerManager
    )
    
    begin {
        Set-StrictMode -Version Latest
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {

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