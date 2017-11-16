Set-StrictMode -Version 'Latest'

$candidatePaths = @('C:\inetpub\sites\Scrap\', 'C:\inetpub\sites\Scrap\Scrap2\', 'C:\inetpub\sites\Scrap\Scrap2\Scrap3\') |
    Get-Item | Sort-Object FullName
$excludedPaths = @('C:\inetpub\sites\Scrap\Scrap2\*')

$candidatePaths | select -exp FullName -PV candidatePath | Where { $excludedPaths.Where({$candidatePath -NotLike $_}) } 

# $candidatePaths | Get-Item | Sort-Object FullName
# $shares = $candidatePaths | Get-Item | Sort-Object FullName

forEach ($candidatePath in $candidatePaths) {
    if ($candidatePath.FullName -eq "") {
        continue
    }

    $isExcluded = $candidatePath | Where-Object { $excludedPaths.Where($_.FullName) }

    #check if path is already present
    if ($excludedPaths -Contains $candidatePath.FullName) {
        Write-Verose $candidatePath.Name "on" $server " is a duplicate of another share."
    }
    else {
        $parent = $candidatePath.FullName
        while ($true) {
            $parent = $parent | Split-Path -parent
            if ($parent -eq "") {
                $sharesCulled += $candidatePath
                break
            }
            if ($sharesCulled.FullName -Contains $parent) {
                Write-Host $candidatePath.Name "on" $server " is a nested share"
                break
            }
        }
    }
}