function Get-IISSiteAclPath {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [switch] $Recurse
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        $allSiteInfos = @()
        $allSiteInfos += Get-IISSiteAclPathHelper
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
                $siteAclPaths = Get-IISSiteAclPathHelper $siteName -Recurse:$Recurse
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
}