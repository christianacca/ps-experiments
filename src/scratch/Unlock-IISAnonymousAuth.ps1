function Unlock-IISAnonymousAuth {
    [CmdletBinding()]
    param (
        [string] $Location
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        . "$PSScriptRoot\Unlock-IISConfigSection.ps1"
        # . .\src\scratch\Unlock-IISConfigSection.ps1
    }
    
    process {
        try {
            $ErrorActionPreference = 'Stop'

            Unlock-IISConfigSection `
                -SectionPath 'system.webServer/security/authentication/anonymousAuthentication' `
                -Location $Location            
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}