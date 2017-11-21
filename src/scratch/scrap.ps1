Get-Module IISSiteInstall -All | Remove-Module
Import-Module .\src\IISSiteInstall\IISSiteInstall\IISSiteInstall.psd1

$testSiteName = "Scrap-$(New-Guid)"
$testSitePath = "C:\inetpub\sites\$testSiteName"
$testAppPoolName = "$testSiteName-AppPool"
$testAppPoolUsername = "IIS AppPool\$testAppPoolName"
$testLocalUser = 'PesterTestUser'

Reset-IISServerManager -Confirm:$false

try {
    $user = try {
        Get-LocalUser $testLocalUser -EA Stop
    }
    catch {
        New-LocalUser $testLocalUser -Password (ConvertTo-SecureString '(pe$ter4powershell)' -AsPlainText -Force)
    } 
    # New-CaccaIISWebsite $testSiteName -Force -AppPoolIdentity $testLocalUser
    New-CaccaIISWebsite $testSiteName -Force -AppPoolIdentity "$($env:COMPUTERNAME)\$testLocalUser"
    (Get-Item $testSitePath).GetAccessControl('Access').Access | ? IsInherited -eq $false | Select -Exp IdentityReference -Unique        
    Get-CaccaIISSiteAclPath $testSiteName
}
finally {
    Remove-CaccaIISWebsite $testSiteName
    Get-LocalUser $testLocalUser | Remove-LocalUser
    Remove-Item $testSitePath
}

(Get-IISAppPool $testAppPoolName).ProcessModel


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