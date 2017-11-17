#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function Get-IISSiteHierarchyInfo {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string] $Name
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Version 'Latest'
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

            Get-IISSite @siteParams -PV site -WA SilentlyContinue |
                Select-Object -Exp Applications -PV app |
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