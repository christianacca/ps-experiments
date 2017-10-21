function BadFunc {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Value
    )
    begin {
        $counter = 0
    }
    process {
        $callerEA = $ErrorActionPreference
        try {
            $counter++
            if ($counter -eq 3) {
                throw 'Do NOT like three'
            }
            "$Value - $counter"
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}

function GoodFunc {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Value
    )
    process {
        "$Value - $Value"
    }
}
Clear-Host

$ErrorActionPreference = 'Stop'
@('a', 'b', 'c', 'd') | BadFunc -EA 'Continue' | GoodFunc