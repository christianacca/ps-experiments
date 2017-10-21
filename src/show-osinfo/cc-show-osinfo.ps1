function Show-OSInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ComputerName')]
        [string[]]$ComputerName,

        # Parameter help description
        [Parameter(Mandatory, ParameterSetName = 'File')]
        [string]$FileName
    )
    begin {
        $callerEA = $ErrorActionPreference
        
        . .\src\show-osinfo\cc-new-cimsession.ps1
        . .\src\show-osinfo\cc-get-osinfo.ps1

        if ($PSBoundParameters.ContainsKey('File')) { 
            $ComputerName = Get-Content -Path $FileName -EA Stop
        }
    }
    process {
        try {

            $ComputerName | 
                cNew-CimSession | 
                cGet-OSInfo |
                Format-Table -AutoSize
            
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}