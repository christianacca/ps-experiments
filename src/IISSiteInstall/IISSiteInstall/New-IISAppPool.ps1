#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function New-IISAppPool {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [scriptblock] $Config,

        [switch] $PassThru,

        [switch] $Force,

        [switch] $Commit
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        if ($Config -eq $null) {
            $Config = {}
        }
        if (!$PSBoundParameters.ContainsKey('Commit')) {
            $Commit = $true
        }
    }
    
    process {
        try {
            
            [Microsoft.Web.Administration.ServerManager] $manager = Get-IISServerManager

            $existingPool = $manager.ApplicationPools[$Name]

            if (!$Force -and $existingPool) {
                throw "App pool '$Name' already exists. Supply -Force to overwrite"
            }

            if ($Commit) {
                Start-IISCommitDelay
            }
            try {
                if ($existingPool) {
                    if ($PSCmdlet.ShouldProcess($Name, 'Remove existing App pool')) {
                        $manager.ApplicationPools.Remove($existingPool)
                    }
                }

                if ($PSCmdlet.ShouldProcess($Name, 'Create App pool')) {
                    [Microsoft.Web.Administration.ApplicationPool] $pool = $manager.ApplicationPools.Add($Name)
                    $pool.ManagedPipelineMode = "Integrated"
                    $pool.ManagedRuntimeVersion = "v4.0"
                    $pool.Enable32BitAppOnWin64 = $true # this IS the recommended default even for 64bit servers
                    $pool.AutoStart = $true
                    $pool | ForEach-Object $Config

                    if ($PassThru) {
                        $pool
                    }
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