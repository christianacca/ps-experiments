#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function Get-IISSiteHierarchyInfo {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $AppName
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {
            $siteParams = if ([string]::IsNullOrWhiteSpace($Name)) {
                @{}
            }
            else {
                @{
                    Name = $Name
                }
            }

            if (![string]::IsNullOrWhiteSpace($AppName) -and !$AppName.StartsWith('/')) {
                $AppName = '/' + $AppName
            }

            Get-IISSite @siteParams -PV site -WA SilentlyContinue |
                Select-Object -Exp Applications -PV app |
                Where-Object { !$AppName -or $_.Path -eq $AppName } |
                ForEach-Object {
                    $existingPool = Get-IISAppPool -Name $_.ApplicationPoolName -WA SilentlyContinue
                    if (!$existingPool) {
                        ''
                    }
                    else {
                        $existingPool
                    }
                } -PV pool |
                select  `
            @{n = 'Site_Name'; e = {$site.Name}},
            @{n = 'App_Path'; e = {$app.Path}}, 
            @{n = 'App_PhysicalPath'; e = {$app.VirtualDirectories[0].PhysicalPath}}, 
            @{n = 'AppPool_Name'; e = { if ($pool) { $app.ApplicationPoolName } }},
            @{n = 'AppPool_IdentityType'; e = { if ($pool) { $pool.ProcessModel.IdentityType} }},
            @{n = 'AppPool_Username'; e = { if ($pool) { Get-IISAppPoolUsername $pool } }}
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }

    end {
    }
}