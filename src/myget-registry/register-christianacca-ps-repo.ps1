Import-Module PowerShellGet

$repo = @{
    Name = 'christianacca-ps'
    SourceLocation = 'https://www.myget.org/F/christianacca-ps/api/v2'
    ScriptSourceLocation = 'https://www.myget.org/F/christianacca-ps/api/v2/'
    PublishLocation = 'https://www.myget.org/F/christianacca-ps/api/v2/package'
    ScriptPublishLocation = 'https://www.myget.org/F/christianacca-ps/api/v2/package/'
    InstallationPolicy = 'Trusted'
}
Register-PSRepository @repo