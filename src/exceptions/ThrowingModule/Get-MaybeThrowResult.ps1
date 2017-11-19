function Get-MaybeThrowResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )
    
    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        Write-Host "Get-MaybeThrowResult.callerEA: $callerEA"
        Write-Host "Get-MaybeThrowResult.ErrorActionPreference: $ErrorActionPreference"
    }
    
    process {
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