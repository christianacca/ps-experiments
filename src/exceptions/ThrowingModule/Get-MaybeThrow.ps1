function Get-MaybeThrow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )
    
    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $callerVerbosePref = $VerbosePreference
        $callerInformationPref = $InformationPreference
        $ErrorActionPreference = 'Stop'
        $VerbosePreference = 'SilentlyContinue'
        $InformationPreference = 'SilentlyContinue'

        Write-Host "Get-MaybeThrow.callerEA: $callerEA" -InformationAction 'Continue'
        Write-Host "Get-MaybeThrow.ErrorActionPreference: $ErrorActionPreference" -InformationAction 'Continue'
        Write-Host "Get-MaybeThrow.callerVerbosePref: $callerVerbosePref" -InformationAction 'Continue'
        Write-Host "Get-MaybeThrow.VerbosePreference: $VerbosePreference" -InformationAction 'Continue'
        Write-Host "Get-MaybeThrow.callerInformationPref: $callerInformationPref" -InformationAction 'Continue'
        Write-Host "Get-MaybeThrow.InformationPreference: $InformationPreference" -InformationAction 'Continue'
    }
    
    process {
        try {
            if ($Name -eq '?') {
                # throw 'Object not found, try another name.'
                throw [ThrowingModuleException]::New('Object not found, try another name.')
            }
            [PsCustomObject] @{
                Name = $Name
            }

            Write-Host 'Get-MaybeThrow... still running' -InformationAction 'Continue'

        }
        catch {
            Write-Host "Get-MaybeThrow... catch '$_'" -InformationAction 'Continue'
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}