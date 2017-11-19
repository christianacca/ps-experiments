function Get-MaybeThrowResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {
            Get-MaybeThrow $Name
            Write-Host 'Get-MaybeThrowResult... still running'

        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}