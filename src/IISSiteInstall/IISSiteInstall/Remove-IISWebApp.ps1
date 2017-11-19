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
        [string] $Name
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Version 'Latest'

        $SiteName = $SiteName.Trim()
        $Name = $Name.Trim()

        if (!$Name.StartsWith('/')) {
            $Name = '/' + $Name
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

            $aclInfo = @{
                AppPath             = $app.VirtualDirectories['/'].PhysicalPath
                AppPoolName         = $app.ApplicationPoolName
                SkipTempAspNetFiles = $true
            }
            # note: we should NOT have to explicitly 'pass' WhatIfPreference (bug in PS?)
            Remove-CaccaIISSiteAcl @aclInfo -WhatIf:$WhatIfPreference

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
                Write-Debug "Remove-IISWebApp: error thrown '$_'"
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