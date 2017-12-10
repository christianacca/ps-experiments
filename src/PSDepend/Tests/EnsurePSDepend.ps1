function EnsurePSDepend {
    param(
        [string] $PsDependVs = '0.1.56.4'
    )
    try {
        Get-InstalledModule PSDepend -RequiredVersion $PsDependVs -EA Stop
    }
    catch {
        Install-Module PSDepend -RequiredVersion $PsDependVs  -Repository christianacca-ps  
    }
    Import-Module PSDepend -RequiredVersion $PsDependVs
}