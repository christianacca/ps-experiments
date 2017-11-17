#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function New-IISWebApp {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $SiteName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $AppPoolName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [scriptblock] $AppPoolConfig,

        [Parameter(ValueFromPipeline)]
        [string[]] $ModifyPaths,

        [Parameter(ValueFromPipeline)]
        [string[]] $ExecutePaths,

        [switch] $Force,
        
        [switch] $Commit
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

        if (!$PSBoundParameters.ContainsKey('Commit')) {
            $Commit = $true
        }
    }
    
    process {
        try {
            $site = Get-IISSite $SiteName
            if (!$site) {
                return
            }

            $qualifiedAppName = "$SiteName$Name"

            $existingApp = $site.Applications[$Name]
            if ($existingApp -and !$Force) {
                throw "Web Application '$qualifiedAppName' already exists. To overwrite you must supply -Force"
            }

            $rootApp = $site.Applications['/']
            if ([string]::IsNullOrWhiteSpace($AppPoolName)) {
                $AppPoolName = $rootApp.ApplicationPoolName
            }

            $childPath = if ([string]::IsNullOrWhiteSpace($Path)) {
                $sitePath = $rootApp.VirtualDirectories['/'].PhysicalPath
                Join-Path $sitePath $Name
            } else {
                $Path
            }
            
            if (-not(Test-Path $childPath)) {
                New-Item $childPath -ItemType Directory | Out-Null
            }

            if ($Commit) {
                Start-IISCommitDelay
            }

            try {
                if ($existingApp) {
                    Remove-IISWebApp $SiteName $Name -Commit:$false
                }

                if (-not(Get-IISAppPool $AppPoolName -WA SilentlyContinue)) {
                    New-IISAppPool $AppPoolName -Commit:$false | Out-Null
                }

                if ($AppPoolConfig) {
                    Get-IISAppPool $AppPoolName | ForEach-Object $AppPoolConfig | Out-Null
                }

                if ($PSCmdlet.ShouldProcess($qualifiedAppName, 'Create Web Application')) {
                    $app = $site.Applications.Add($Name, $childPath)
                    $app.ApplicationPoolName = $AppPoolName
                }

                if($Commit) {
                    Stop-IISCommitDelay
                }
            }
            catch {
                if ($Commit) {
                    Stop-IISCommitDelay -Commit:$false
                }
                throw
            }

            (Get-IISSite $SiteName).Applications[$Name]
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }

    end {
    }
}