Get-Module IISSiteInstall -All | Remove-Module
Import-Module .\src\IISSiteInstall\IISSiteInstall\IISSiteInstall.psd1


$testSiteName = "Scrap-$(New-Guid)"
$testSitePath = "C:\inetpub\sites\$testSiteName"
$testAppPoolName = "$testSiteName-AppPool"
$testAppPoolUsername = "IIS AppPool\$testAppPoolName"

Reset-IISServerManager -Confirm:$false

try {

    Get-IISSite 'Scrap-defa3fe4-cc70-4c0f-8d12-73151190d50e' | Select-Object -Exp Bindings

    New-CaccaIISWebsite $testSiteName | Out-Null
    Get-IISSite | Select-Object -PV


    # New-CaccaIISWebsite $testSiteName -Force -AppPoolIdentity $testLocalUser
    # New-CaccaIISWebsite $testSiteName -Force -AppPoolIdentity "$($env:COMPUTERNAME)\$testLocalUser"
    # (Get-Item $testSitePath).GetAccessControl('Access').Access | ? IsInherited -eq $false | Select -Exp IdentityReference -Unique        
    # Get-CaccaIISSiteAclPath $testSiteName
}
finally {
    Remove-CaccaIISWebsite $testSiteName
    Remove-Item $testSitePath
}

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