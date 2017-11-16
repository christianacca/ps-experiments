#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function Get-IISSiteAclPath {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [switch] $ExcludeShared,

        [switch] $Recurse
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Version 'Latest'

        $allSiteInfos = @()
        $allSiteInfos += Get-IISSiteAclPathCoreInfo
    }
    
    process {
        try {

            $siteInfos = if ([string]::IsNullOrWhiteSpace($Name)) {
                $allSiteInfos
            }
            else {
                $allSiteInfos | Where-Object SiteName -eq $Name
            }

            $siteNames = @()
            $siteNames += $siteInfos | Select-Object -Exp SiteName -Unique

            foreach ($siteName in $siteNames) {
                $siteAclPaths = Get-IISSiteAclPathCoreInfo $siteName -Recurse:$Recurse
                $otherSiteAclPaths = $allSiteInfos | Where-Object SiteName -ne $siteName

                Write-Debug "Acl Paths: $siteAclPaths"
                
                $siteAclPaths | ForEach-Object {
                    $path = $_.Path
                    $identityReference = $_.IdentityReference
                    $isShared = ($otherSiteAclPaths | 
                        Where-Object { $_.Path -eq $path -and $_.IdentityReference -eq $identityReference } |
                        Measure-Object).Count -ne 0
                    $_ | Select-Object -Property *, @{ n='IsShared'; e={$isShared}}
                }                
            }

        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }

    end {
    }
}