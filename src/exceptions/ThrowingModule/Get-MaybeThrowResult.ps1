function Get-MaybeThrowResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )
    
    begin {
        # `Get-CallerPreference` will result in the context of the *caller* to be used to
        # assign $XxxPreference automatic variables
        # When the caller is a script running in the powershell host (eg console) calling
        # `Get-CallerPreference` is redundant.
        # Only when the caller is another module does `Get-CallerPreference` become relevant.
        # In this case the preference variables from the calling module will be received.
        # This is more intutive as the calling module can now set the $XxxPreference automatic
        # variable globally without having to explicitly pass preference *arguments* to
        # in calls to functions/cmdlets that reside in other modules.
        # In affect the calling module is in charge of the behaviour of it's internal
        # calls to other modules
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