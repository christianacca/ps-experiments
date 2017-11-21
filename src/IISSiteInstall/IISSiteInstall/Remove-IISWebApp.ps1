#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function Remove-IISWebApp {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $SiteName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $ModifyPaths,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $ExecutePaths
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        $SiteName = $SiteName.Trim()
        $Name = $Name.Trim()

        if (!$Name.StartsWith('/')) {
            $Name = '/' + $Name
        }

        if ($ModifyPaths -eq $null) {
            $ModifyPaths = @()
        }
        if ($ExecutePaths -eq $null) {
            $ExecutePaths = @()
        }
    }
    
    process {
        try {
            # note: NOT throwing to be consistent with IISAdministration\Remove-IISSite
            $site = Get-IISSite $SiteName
            if (!$site) {
                return
            }

            # note: NOT throwing to be consistent with IISAdministration\Remove-IISSite
            $app = $site.Applications[$Name]
            if (!$app) {
                Write-Warning "Web Application '$SiteName$Name' does not exist"
                return
            }

            $appPoolIdentity = Get-IISAppPool ($app.ApplicationPoolName) | Get-IISAppPoolUsername
            $aclInfo = @{
                AppPath             = $app.VirtualDirectories['/'].PhysicalPath
                AppPoolIdentity     = $appPoolIdentity
                ModifyPaths         = $ModifyPaths
                ExecutePaths        = $ExecutePaths
                SkipMissingPaths    = $true
                # file permissions for Temp AP.Net Files folders *might* be shared so must skip removing these
                # cleaning up orphaned file permissions will happen below when 'Remove-IISAppPool' is run
                SkipTempAspNetFiles = $true
            }
            Remove-CaccaIISSiteAcl @aclInfo

            Start-IISCommitDelay
            try {

                if ($PSCmdlet.ShouldProcess("$SiteName$Name", 'Remove Web Application')) {
                    $site.Applications.Remove($app)
                }

                if ($WhatIfPreference -ne $true) {
                    # note: skipping errors when deleting app pool when that pool is shared by other sites/apps
                    Remove-IISAppPool ($app.ApplicationPoolName) -EA Ignore -Commit:$false
                }

                Stop-IISCommitDelay
            }
            catch {
                Stop-IISCommitDelay -Commit:$false
                throw
            }
            finally {
                Reset-IISServerManager -Confirm:$false -WhatIf:$false
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}