function Set-MaybeThrowResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [switch] $PassThru
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        Write-Host "Set-MaybeThrowResult.callerEA: $callerEA"
        Write-Host "Set-MaybeThrowResult.begin.ErrorActionPreference: $ErrorActionPreference"
    }
    
    process {
        Write-Host "Set-MaybeThrowResult.process.ErrorActionPreference: $ErrorActionPreference"
        try {
            $value = Get-MaybeThrowResult $Name
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