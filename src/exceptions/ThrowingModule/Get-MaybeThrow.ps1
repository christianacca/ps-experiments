function Get-MaybeThrow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )
    
    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        Write-Host "Get-MaybeThrow.callerEA: $callerEA"
        Write-Host "Get-MaybeThrow.ErrorActionPreference: $ErrorActionPreference"
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