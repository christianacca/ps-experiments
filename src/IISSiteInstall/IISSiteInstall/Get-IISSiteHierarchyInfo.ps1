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

            Get-IISSite @siteParams -PV site |
                Select-Object -Exp Applications -PV app |
                Get-IISAppPool -Name {$_.ApplicationPoolName} -PV pool |
                select  `
            @{n = 'Site_Name'; e = {$site.Name}},
            @{n = 'App_Path'; e = {$app.Path}}, 
            @{n = 'App_PhysicalPath'; e = {$app.VirtualDirectories[0].PhysicalPath}}, 
            @{n = 'AppPool_Name'; e = {$app.ApplicationPoolName}},
            @{n = 'AppPool_IdentityType'; e = {$pool.ProcessModel.IdentityType}},
            @{n = 'AppPool_Username'; e = {Get-IISAppPoolUsername $pool}}
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }

    end {
    }
}