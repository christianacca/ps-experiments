#Requires -Version 5.0 -Modules IISAdministration

function Unlock-IISConfigSection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName='Path')]
        [string] $SectionPath,
        [Parameter(Mandatory, ParameterSetName='Config')]
        [Microsoft.Web.Administration.Configuration] $Section,
        [string] $Location,
        [Microsoft.Web.Administration.ServerManager] $ServerManager
    )
    
    begin {
        $callerEA = $ErrorActionPreference
    }
    
    process {
        try {
            $ErrorActionPreference = 'Stop'

            if (-not $ServerManager) {
                $ServerManager = Get-IISServerManager
            }

            $sectionConfig = if ($Section.IsPresent) { 
                $Section
            }
            else {
                Get-IISConfigSection $SectionPath -Location $Location
            }
            $sectionConfig.OverrideMode = 'Allow'
            
            if (-not $PSBoundParameters.ContainsKey('ServerManager')) {
                $ServerManager.CommitChanges()
            }
            
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}