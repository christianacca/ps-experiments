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

        . "$PSScriptRoot\New-CimSessionHelper.ps1"
        . "$PSScriptRoot\Get-OsInfoHelper.ps1"

        if ($PSCmdlet.ParameterSetName -eq 'File') { 
            $ComputerName = Get-Content -Path $FileName -EA Stop
        }
    }
    process {
        try {

            $ComputerName | 
                New-CimSessionHelper | 
                Get-OSInfoHelper |
                Format-Table -AutoSize
            
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}