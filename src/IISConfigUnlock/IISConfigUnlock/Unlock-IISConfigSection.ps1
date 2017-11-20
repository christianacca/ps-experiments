function Unlock-IISConfigSection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName='Path', ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $SectionPath,

        [Parameter(Mandatory, ParameterSetName='Config', ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Web.Administration.ConfigurationSection] $Section,

        [string] $Location,

        [switch] $Commit
    )
    
    begin {
        Set-StrictMode -Version Latest
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        if (!$PSBoundParameters.ContainsKey('Commit')) {
            $Commit = $true
        }
    }
    
    process {
        try {

            if ($Commit) {
                Start-IISCommitDelay
            }

            $sectionConfig = if ($Section) { 
                $Section
            }
            else {
                Get-IISConfigSection $SectionPath -Location $Location
            }

            $sectionConfig.OverrideMode = 'Allow'
            
            if ($Commit) {
                Stop-IISCommitDelay
            }
            
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}