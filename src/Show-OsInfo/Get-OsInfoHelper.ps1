function Get-OsInfoHelper {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [CimSession]$CimSession
    )
    begin {
        $callerEA = $ErrorActionPreference
    }
    process {
        try {

            $ErrorActionPreference = 'Stop'
    
            $os = Get-CimInstance -CimSession $CimSession -ClassName Win32_OperatingSystem
            $cs = Get-CimInstance -CimSession $CimSession -ClassName Win32_ComputerSystem
    
            $properties = @{
                ComputerName = $CimSession.ComputerName
                Mfgr         = $cs.Manufacturer
                Model        = $cs.Model
                OSVersion    = $os.Version
                RAM          = ($cs.TotalPhysicalMemory / 1GB -as [int])
            }
            New-Object -TypeName psobject -Property $properties
    
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}