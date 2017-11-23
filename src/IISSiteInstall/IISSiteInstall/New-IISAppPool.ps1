#Requires -RunAsAdministrator

function New-IISAppPool {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [PSCredential] $Credential,

        [Parameter(ValueFromPipelineByPropertyName)]
        [scriptblock] $Config,

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
    }
    
    process {
        try {
            
            if ($Config -eq $null) {
                $Config = {}
            }

            [Microsoft.Web.Administration.ServerManager] $manager = Get-IISServerManager

            $existingPool = $manager.ApplicationPools[$Name]

            if (!$Force -and $existingPool) {
                throw "App pool '$Name' already exists. Supply -Force to overwrite"
            }

            if ($Commit) {
                Start-IISCommitDelay
            }
            try {
                if ($existingPool -and $PSCmdlet.ShouldProcess($Name, 'Remove App pool')) {
                    # note: not using Remove-IISAppPool as do NOT want to remove file permissions
                    $manager.ApplicationPools.Remove($existingPool)
                }

                if ($PSCmdlet.ShouldProcess($Name, 'Create App pool')) {
                    [Microsoft.Web.Administration.ApplicationPool] $pool = $manager.ApplicationPools.Add($Name)

                    if ($Credential) {
                        Set-IISAppPoolUser $pool $Credential
                    }

                    # todo: do NOT set this when it's detected that OS is 64bit onlys
                    $pool.Enable32BitAppOnWin64 = $true # this IS the recommended default even for 64bit servers

                    $pool | ForEach-Object $Config
                    $pool
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