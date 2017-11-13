#Requires -RunAsAdministrator
#Requires -Modules IISAdministration

function Get-IISSiteAclPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [switch] $Recurse
    )
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Version 'Latest'
    }
    
    process {
        try {
            $siteInfo = Get-IISSiteHierarchyInfo $Name

            $appPoolUsernames = @()
            $appPoolUsernames += $siteInfo | Select-Object -Exp AppPool_Username | Select -Unique

            $candidatePaths = @()

            $sitePaths = @()
            $sitePaths += $siteInfo | Select-Object -Exp App_PhysicalPath | Where-Object { Test-Path $_ }

            Write-Debug "Site Path count: $(($sitePaths | measure).Count)"

            # note: excluding node_modules for perf reasons (hopefully no site adds permissions to specific node modules!)
            $siteSubPaths = @()
            if ($Recurse) {
                $siteSubPaths += Get-ChildItem $sitePaths -Recurse -Directory -Depth 5 -Exclude 'node_modules' |
                    Select-Object -Exp FullName
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

            Write-Debug "All Site candidate paths count: $(($sitePaths | measure).Count)"

            $candidatePaths += $uniqueSitePaths
            $candidatePaths += Get-CaccaTempAspNetFilesPaths

            foreach ($username in $appPoolUsernames) {
                $candidatePaths | ForEach-Object {
                    $path = $_
                    (Get-Item $path).GetAccessControl('Access').Access |
                        Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $username } |
                        Select-Object @{n = 'Path'; e = {$path}}, @{n = 'IdentityReference'; e = {$username}}
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