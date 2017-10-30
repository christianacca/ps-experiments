$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

. C:\Git\ps-experiments\src\local-registry\Publish-GithubScript.ps1

$params = @{
    UrlPath = 'https://raw.githubusercontent.com/christianacca/Toolbox/ps-script-header/PowerShell'
    Repository = 'LocalRepo'
}
Publish-GithubScript Add-Hostnames @params
Publish-GithubScript Remove-Hostnames @params
Publish-GithubScript Add-BackConnectionHostNames @params
Publish-GithubScript Remove-BackConnectionHostNames @params