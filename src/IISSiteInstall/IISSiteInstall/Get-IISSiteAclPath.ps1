#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function Get-IISSiteAclPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Version 'Latest'
    }
    
    process {
        try {
            $siteInfo = Get-IISSiteHierarchyInfo $Name
            $candidatePaths = @()
            $candidatePaths += Get-IISSiteHierarchyInfo $Name | Select-Object -Exp App_PhysicalPath
            $candidatePaths += Get-CaccaTempAspNetFilesPaths
            
            $candidatePaths | Where-Object {
                (Get-Item $_).GetAccessControl('Access').Access |
                    Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $siteInfo.AppPool_Username }
            }

        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }

    end {
    }
}