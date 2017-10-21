function cNew-CimSession {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$ComputerName
    )
    begin {
        . .\src\exceptions\try-first.ps1
        $callerEA = $ErrorActionPreference
    }
    process {
        try {

            $tryCim = {
                Write-Verbose "Attempting CIM Session to $ComputerName"
                New-CimSession $ComputerName
            }
            $tryDcom = {
                Write-Verbose "Attempty DCOM session to $ComputerName"
                New-CimSession $ComputerName -SessionOption (New-CimSessionOption -Protocol Dcom)
            }
            $session = Try-First $tryCim, $tryDcom
            if (-not $session) {
                throw "Failed to connect to $ComputerName"
            }
            Write-Output $session
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}