function Get-MaybeThrow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        Write-Verbose "Get-MaybeThrow.callerEA: $callerEA"
    }
    
    process {
        try {
            if ($Name -eq '?') {
                throw 'Object not found, try another name.'
            }
            [PsCustomObject] @{
                Name = $Name
            }

        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}