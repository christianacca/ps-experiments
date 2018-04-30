function Set-MaybeThrowResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [switch] $PassThru
    )
    
    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $callerVerbosePref = $VerbosePreference
        $callerInformationPref = $InformationPreference
        $ErrorActionPreference = 'Stop'
        $VerbosePreference = 'Stop'
        $InformationPreference = 'Continue'

        Write-Host "Set-MaybeThrowResult.callerEA: $callerEA"
        Write-Host "Set-MaybeThrowResult.ErrorActionPreference: $ErrorActionPreference"
        Write-Host "Set-MaybeThrowResult.callerVerbosePref: $callerVerbosePref"
        Write-Host "Set-MaybeThrowResult.VerbosePreference: $VerbosePreference"
        Write-Host "Set-MaybeThrowResult.callerInformationPref: $callerInformationPref"
        Write-Host "Set-MaybeThrowResult.InformationPreference: $InformationPreference"
    }
    
    process {
        try {
            $value = Get-CaccaMaybeThrowResult $Name
            if ($PassThru) {
                $value
            }

            Write-Host 'Set-MaybeThrowResult... still running' -InformationAction 'Continue'

        }
        catch {
            Write-Host "Set-MaybeThrowResult... catch '$_'" -InformationAction 'Continue'
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}