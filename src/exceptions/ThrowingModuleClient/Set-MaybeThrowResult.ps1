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
    }
    
    process {
        try {
            $value = Get-MaybeThrowResult $Name
            if ($PassThru) {
                $value
            }

            Write-Host 'Set-MaybeThrowResult... still running'

        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}