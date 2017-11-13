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

            $appPoolUsernames = @()
            $appPoolUsernames += $siteInfo | Select-Object -Exp AppPool_Username | Select -Unique

            $candidatePaths = @()

            $sitePaths = Get-IISSiteHierarchyInfo $Name | Select-Object -Exp App_PhysicalPath
            # note: excluding node_modules for perf reasons (hopefully no site adds permissions to specific node modules!)
            $siteSubPaths = Get-ChildItem $sitePaths -Recurse -Directory -Depth 5 -Exclude 'node_modules' |
                Select-Object -Exp FullName
            $uniqueFolderPaths = $sitePaths + $siteSubPaths | Select -Unique

            $siteFilePaths = @('*.bat', '*.exe', '*.ps1') | ForEach-Object {
                Get-ChildItem $uniqueFolderPaths -Recurse -File -Depth 5 -Filter $_ |
                    Select-Object -Exp FullName
            }
            $uniqueSitePaths = $uniqueFolderPaths + $siteFilePaths | Select -Unique

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