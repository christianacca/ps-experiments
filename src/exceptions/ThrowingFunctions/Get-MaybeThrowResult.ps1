function Get-MaybeThrowResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        Write-Host "Get-MaybeThrowResult.callerEA: $callerEA"
        Write-Host "Get-MaybeThrowResult.begin.ErrorActionPreference: $ErrorActionPreference"
    }
    
    process {
        Write-Host "Get-MaybeThrowResult.process.ErrorActionPreference: $ErrorActionPreference"
        try {
            Get-MaybeThrow $Name
            Write-Host 'Get-MaybeThrowResult... still running'
        }
        catch {
            Write-Host "Get-MaybeThrowResult... catch '$_'"
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}