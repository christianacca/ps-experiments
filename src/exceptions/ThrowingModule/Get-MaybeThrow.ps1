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
        $ErrorActionPreference = 'Stop'
        $VerbosePreference = 'SilentlyContinue'

        Write-Host "Get-MaybeThrow.callerEA: $callerEA"
        Write-Host "Get-MaybeThrow.ErrorActionPreference: $ErrorActionPreference"
        Write-Host "Get-MaybeThrow.callerVerbosePref: $callerVerbosePref"
        Write-Host "Get-MaybeThrow.VerbosePreference: $VerbosePreference"
    }
    
    process {
        try {
            if ($Name -eq '?') {
                throw 'Object not found, try another name.'
            }
            [PsCustomObject] @{
                Name = $Name
            }

            Write-Host 'Get-MaybeThrow... still running'

        }
        catch {
            Write-Host "Get-MaybeThrow... catch '$_'"
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}