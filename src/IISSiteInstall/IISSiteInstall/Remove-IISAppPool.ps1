#Requires -RunAsAdministrator

function Remove-IISAppPool {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [switch] $Force,

        [switch] $Commit
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        if (!$PSBoundParameters.ContainsKey('Commit')) {
            $Commit = $true
        }

        $existingSiteInfo = if ($Force) {
            @()
        } else {
            Get-IISSiteHierarchyInfo
        }
    }
    
    process {
        try {
            
            [Microsoft.Web.Administration.ServerManager] $manager = Get-IISServerManager

            if ($Commit) {
                Start-IISCommitDelay
            }
            try {
                $pool = $manager.ApplicationPools[$Name]
                
                if (!$pool) {
                    throw "Cannot delete AppPool, '$Name' does not exist"
                }
                $inUse = $existingSiteInfo | Where-Object AppPool_Name -eq $Name
                if ($inUse) {
                    throw "Cannot delete AppPool, '$Name' is used by one or more Web applications/sites"
                }

                if ($PSCmdlet.ShouldProcess($Name, 'Removing App pool')) {
                    $manager.ApplicationPools.Remove($pool)
                }
                
                if ($Commit) {
                    Stop-IISCommitDelay
                }
            }
            catch {
                if ($Commit) {
                    Stop-IISCommitDelay -Commit:$false
                }
                throw
            }

        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}