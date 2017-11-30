function EnsurePSDepend {
    param(
        [string] $PsDependVs = '0.1.56.1'
    )
    try {
        Get-InstalledModule PSDepend -RequiredVersion $PsDependVs -EA Stop
    }
    catch {
        Install-Module PSDepend -RequiredVersion $PsDependVs  -Repository christianacca-ps  
    }
    Import-Module PSDepend -RequiredVersion $PsDependVs
}