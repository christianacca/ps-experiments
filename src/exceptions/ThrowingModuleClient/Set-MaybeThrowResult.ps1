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
        $ErrorActionPreference = 'Stop'
        $VerbosePreference = 'Stop'

        Write-Host "Set-MaybeThrowResult.callerEA: $callerEA"
        Write-Host "Set-MaybeThrowResult.ErrorActionPreference: $ErrorActionPreference"
        Write-Host "Set-MaybeThrowResult.callerVerbosePref: $callerVerbosePref"
        Write-Host "Set-MaybeThrowResult.VerbosePreference: $VerbosePreference"
    }
    
    process {
        try {
            $value = Get-CaccaMaybeThrowResult $Name
            if ($PassThru) {
                $value
            }

            Write-Host 'Set-MaybeThrowResult... still running'

        }
        catch {
            Write-Host "Set-MaybeThrowResult... catch '$_'"
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}