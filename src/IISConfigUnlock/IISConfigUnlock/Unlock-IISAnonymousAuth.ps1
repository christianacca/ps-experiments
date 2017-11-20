function Unlock-IISAnonymousAuth {
    [CmdletBinding()]
    param (
        [string] $Location,
        [switch] $Commit
    )
    
    begin {
        Set-StrictMode -Version Latest
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        if (!$PSBoundParameters.ContainsKey('Commit')) {
            $Commit = $true
        }
    }
    
    process {
        try {
            $sectionPath = 'system.webServer/security/authentication/anonymousAuthentication'
            $sectionPath | Unlock-IISConfigSection -Location $Location -Commit:$Commit
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}