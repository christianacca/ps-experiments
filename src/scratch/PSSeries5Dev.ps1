#Requires -RunAsAdministrator

$InformationPreference = 'Continue'

# Ensure you have latest vs of Powershell package manager
if (-not (Get-PackageProvider -Name Nuget -EA SilentlyContinue)) {
    Write-Information 'Install Nuget PS package provider'
    Get-PackageProvider -Name NuGet -ForceBootstrap -EA Stop | Out-Null
}

# Register PS repository that hosts 'PSSeries5Dev' module
$repo = 'christianacca-ps'
if (-not(Get-PSRepository -Name $repo -EA SilentlyContinue)) {
    Write-Information "Registering custom PS Repository '$repo'"    
    $repoParams = @{
        Name                  = $repo
        SourceLocation        = "https://www.myget.org/F/$repo/api/v2"
        ScriptSourceLocation  = "https://www.myget.org/F/$repo/api/v2/"
        PublishLocation       = "https://www.myget.org/F/$repo/api/v2/package"
        ScriptPublishLocation = "https://www.myget.org/F/$repo/api/v2/package/"
        InstallationPolicy    = 'Trusted'
    }
    Register-PSRepository @repoParams -EA Stop
}

# Install Module and import module...
$version = $args[0]
Write-Information "Using PSSeries5Dev v$version"
if (-not(Get-InstalledModule PSSeries5Dev -RequiredVersion $version -EA Ignore)) {
    Write-Information "Install PSSeries5Dev"    
    Install-Module PSSeries5Dev -Repository $repo -RequiredVersion $version -EA Stop
}
Import-Module PSSeries5Dev -RequiredVersion $version -EA Stop