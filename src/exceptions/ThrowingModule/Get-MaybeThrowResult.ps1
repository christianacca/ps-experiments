function Get-MaybeThrowResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )
    
    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $callerVerbosePref = $VerbosePreference
        $ErrorActionPreference = 'Stop'
        $VerbosePreference = 'Inquire'
        Write-Host "Get-MaybeThrowResult.callerEA: $callerEA"
        Write-Host "Get-MaybeThrowResult.ErrorActionPreference: $ErrorActionPreference"
        Write-Host "Get-MaybeThrowResult.callerVerbosePref: $callerVerbosePref"
        Write-Host "Get-MaybeThrowResult.VerbosePreference: $VerbosePreference"
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