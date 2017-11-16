#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function Get-IISSiteAclPathCoreInfo {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string] $Name,

        [switch] $Recurse
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Version 'Latest'

        $allSiteInfos = Get-IISSiteHierarchyInfo
        $tempAspNetFilesPaths = Get-CaccaTempAspNetFilesPaths
    }
    
    process {
        try {
            $siteInfos = if ([string]::IsNullOrWhiteSpace($Name)) {
                $allSiteInfos
            }
            else {
                $allSiteInfos | Where-Object Site_Name -eq $Name
            }

            $siteNames = @()
            $siteNames += $siteInfos | Select-Object -Exp Site_Name -Unique

            foreach ($siteName in $siteNames) {
                $siteInfo = $siteInfos | Where-Object Site_Name -eq $siteName
                $otherSiteInfos = $allSiteInfos | Where-Object Site_Name -ne $siteName

                $appPoolUsernames = @()
                $appPoolUsernames += $siteInfo | Select-Object -Exp AppPool_Username | Select -Unique
    
                $candidatePaths = @()
    
                $sitePaths = @()
                $sitePaths += $siteInfo | Select-Object -Exp App_PhysicalPath | Where-Object { Test-Path $_ }
    
                $siteSubPaths = @()
                if ($Recurse) {
                    $excludedPaths = @()
                    $excludedPaths += $otherSiteInfos | Select-Object -Exp App_PhysicalPath | ForEach-Object { Join-Path $_ '\*' }
                    # note: excluding node_modules for perf reasons (hopefully no site adds permissions to specific node modules!)
                    $siteSubPaths += Get-ChildItem $sitePaths -Recurse -Directory -Depth 5 -Exclude 'node_modules' |
                        Select-Object -Exp FullName -PV candidatePath | 
                        Where-Object { 
                        $excludedPaths.Count -eq 0 -or $excludedPaths.Where( { (Join-Path $candidatePath '\') -NotLike $_}) 
                    }
                }
    
                $uniqueFolderPaths = $sitePaths + $siteSubPaths | Select -Unique
    
                $siteFilePaths = @()
                if ($Recurse) {
                    $siteFilePaths += @('*.bat', '*.exe', '*.ps1') | ForEach-Object {
                        Get-ChildItem $uniqueFolderPaths -Recurse -File -Depth 5 -Filter $_ |
                            Select-Object -Exp FullName
                    }
                }
                $uniqueSitePaths = $uniqueFolderPaths + $siteFilePaths | Select -Unique
    
                $candidatePaths += $uniqueSitePaths
                $candidatePaths += $tempAspNetFilesPaths
    
                foreach ($username in $appPoolUsernames) {
                    $candidatePaths | ForEach-Object {
                        $path = $_
                        Write-Verbose "Candidate path: '$path'"
                        $select = @(
                            @{n = 'SiteName'; e = {$siteName}},
                            @{n = 'Path'; e = {$path}}, 
                            @{n = 'IdentityReference'; e = {$username}}
                        )
                        (Get-Item $path).GetAccessControl('Access').Access |
                            Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $username } | 
                            Select-Object $select
                    }
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