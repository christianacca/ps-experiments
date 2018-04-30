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

        # IMPORTANT: $InformationPreference is NOT being set from the calling module
        # this is because Get-CallerPreference was written before this preference variable
        # was introduced

        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $callerVerbosePref = $VerbosePreference
        $callerInformationPref = $InformationPreference
        $ErrorActionPreference = 'Stop'
        $VerbosePreference = 'Inquire'
        $InformationPreference = 'Ignore'
        Write-Host "Get-MaybeThrowResult.callerEA: $callerEA" -InformationAction 'Continue'
        Write-Host "Get-MaybeThrowResult.ErrorActionPreference: $ErrorActionPreference" -InformationAction 'Continue'
        Write-Host "Get-MaybeThrowResult.callerVerbosePref: $callerVerbosePref" -InformationAction 'Continue'
        Write-Host "Get-MaybeThrowResult.VerbosePreference: $VerbosePreference" -InformationAction 'Continue'
        Write-Host "Get-MaybeThrowResult.callerInformationPref: $callerInformationPref" -InformationAction 'Continue'
        Write-Host "Get-MaybeThrowResult.InformationPreference: $InformationPreference" -InformationAction 'Continue'
    }
    
    process {
        try {
            Get-MaybeThrow $Name
            Write-Host 'Get-MaybeThrowResult... still running' -InformationAction 'Continue'
        }
        catch {
            Write-Host "Get-MaybeThrowResult... catch '$_'" -InformationAction 'Continue'
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}