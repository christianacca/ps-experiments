#Requires -RunAsAdministrator

function Remove-IISAppPool {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Name')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Object', Position = 0)]
        [Microsoft.Web.Administration.ApplicationPool] $InputObject,

        [switch] $Force,

        [switch] $Commit
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        if (!$PSBoundParameters.ContainsKey('Commit')) {
            $Commit = $true
        }

        $sitesAclPaths = Get-IISSiteAclPath

        $existingSiteInfo = if ($Force) {
            @()
        }
        else {
            Get-IISSiteHierarchyInfo
        }
    }
    
    process {
        try {
            
            [Microsoft.Web.Administration.ServerManager] $manager = Get-IISServerManager

            $pool = if ($InputObject) {
                $InputObject
            }
            else {
                $instance = $manager.ApplicationPools[$Name]
                if (!$instance) {
                    throw "Cannot delete AppPool, '$Name' does not exist"
                }
                $instance
            }            

            $inUse = $existingSiteInfo | Where-Object AppPool_Name -eq $Name
            if ($inUse) {
                throw "Cannot delete AppPool, '$Name' is used by one or more Web applications/sites"
            }

            $appPoolUsername = Get-IISAppPoolUsername $pool
            
            $appPoolIdentityCount = Get-IISAppPool | Get-IISAppPoolUsername | Where-Object { $_ -eq $appPoolUsername } |
                Measure-Object | Select-Object -Exp Count
            $isNonSharedIdentity = $appPoolIdentityCount -lt 2
            $isAppPoolIdentity = $pool.ProcessModel.IdentityType -eq 'ApplicationPoolIdentity'

            $allAclPaths = @()
            if ($isAppPoolIdentity) {
                $allAclPaths += $sitesAclPaths
            }
            if ($isNonSharedIdentity) {
                $allAclPaths += Get-CaccaTempAspNetFilesPaths | ForEach-Object {
                    [PsCustomObject] @{
                        Path = $_
                        IdentityReference = $appPoolUsername
                    }
                }
            }
            $allAclPaths | Where-Object IdentityReference -eq $appPoolUsername | Remove-CaccaUserFromAcl

            if ($Commit) {
                Start-IISCommitDelay
            }
            try {

                if ($PSCmdlet.ShouldProcess($Name, 'Remove App pool')) {
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