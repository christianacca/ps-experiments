Import-Module PowerShellGet

$Path = 'C:\Users\ccrowhurst\Dropbox\ps'

$repo = @{
    Name = 'LocalRepo'
    SourceLocation = $Path
    PublishLocation = $Path
    InstallationPolicy = 'Trusted'
}
Register-PSRepository @repo