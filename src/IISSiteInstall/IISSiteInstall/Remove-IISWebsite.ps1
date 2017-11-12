#Requires -RunAsAdministrator

function Remove-IISWebsite {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [switch] $Commit
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        if (!$PSBoundParameters.ContainsKey('Commit')) {
            $Commit = $true
        }
    }
    
    process {
        try {
            $siteInfo = Get-IISSiteHierarchyInfo $Name
            [Microsoft.Web.Administration.ServerManager] $manager = Get-IISServerManager

            if ($Commit) {
                Start-IISCommitDelay
            }
            try {
                if ($PSCmdlet.ShouldProcess($Name, 'Deleting Website')) {
                    Remove-IISSite $Name -Confirm:$false
                }

                $siteInfo | Select-Object -Exp AppPool_Name -Unique | Remove-IISAppPool -EA Ignore -Commit:$false          
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