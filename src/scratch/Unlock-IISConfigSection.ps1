function Unlock-IISConfigSection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName='Path')]
        [string] $SectionPath,
        [Parameter(Mandatory, ParameterSetName='Config')]
        [Microsoft.Web.Administration.Configuration] $Section,
        [string] $Location
    )
    
    begin {
        $callerEA = $ErrorActionPreference
    }
    
    process {
        try {
            $ErrorActionPreference = 'Stop'

            [Microsoft.Web.Administration.ServerManager]$mngr = Get-IISServerManager
            $sectionConfig = if ($Section.IsPresent) { 
                $Section
            }
            else {
                Get-IISConfigSection $SectionPath -Location $Location
            }
            $sectionConfig.OverrideMode = 'Allow'
            $mngr.CommitChanges()
            
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}