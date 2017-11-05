function Get-Stuff {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {
            if ($Name -eq '?') {
                throw [MyException]::New('Object not found, try another name.')
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