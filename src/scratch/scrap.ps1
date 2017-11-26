Get-Module IISSiteInstall -All | Remove-Module
Import-Module .\src\IISSiteInstall\IISSiteInstall\IISSiteInstall.psd1

Remove-CaccaIISWebsite Series5
# return


$testSiteName = "Scrap-$(New-Guid)"
$testSitePath = "C:\inetpub\sites\$testSiteName"
$testAppPoolName = "$testSiteName-AppPool"
$testAppPoolUsername = "IIS AppPool\$testAppPoolName"

Reset-IISServerManager -Confirm:$false

try {

    New-CaccaIISWebsite $testSiteName -HostName $testSiteName -HostsFileIPAddress '127.0.0.1' -AddHostToBackConnections
    Get-CaccaIISSiteHostsFileEntry $testSiteName | ft -AutoSize -Wrap
    Get-CaccaIISSiteBackConnection $testSiteName | ft -AutoSize -Wrap
}
finally {
    Remove-CaccaIISWebsite $testSiteName
    Remove-Item $testSitePath
}

Get-TecBoxHostnames
Get-TecBoxBackConnectionHostNames

# (Get-IISAppPool $testAppPoolName).ProcessModel


# $subFolder = Join-Path $childPath 'SubPath1'
# New-Item $subFolder -ItemType Directory -Force | Out-Null
# icacls ("$subFolder") /grant:r ("$testAppPoolUsername" + ':(OI)(CI)R') | Out-Null


# Get-CaccaIISSiteAclPath 'Scrap' -Recurse

return

Reset-IISServerManager -Confirm:$false
Remove-CaccaIISWebSite DeleteMeSite -WhatIf

Get-CaccaTempAspNetFilesPaths |  Get-Item -PV pathInfo | % {
    (Get-Item $_.FullName).GetAccessControl('Access').Access | ? IsInherited -eq $false | Select -Exp IdentityReference -Unique
} |
select @{n='Path'; e={$pathInfo.FullName}}, @{n='IdentityReference'; e={$_}} |
? IdentityReference -Like 'S-*' |
% {
    $user = $_.IdentityReference
    $path = $_.Path
    $acl = (Get-Item $path).GetAccessControl('Access')
    $acl.Access | 
        Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $user } -EA Ignore |
        ForEach-Object { $acl.RemoveAccessRuleAll($_) }
    Set-Acl -Path ($path) -AclObject $acl
}