Get-Module IISSiteInstall -All | Remove-Module
Import-Module .\src\IISSiteInstall\IISSiteInstall\IISSiteInstall.psd1

Remove-IISSite 'Scrap' -Confirm:$false
Remove-IISSite 'Scrap2' -Confirm:$false
$testSiteName = 'Scrap'
$childPath = "C:\inetpub\sites\$testSiteName\MyApp1"
$child2Path = "C:\inetpub\sites\$testSiteName\MyApp2"
$testAppPoolName = "$testSiteName-AppPool"
$testAppPoolUsername = "IIS AppPool\$testAppPoolName"

[Microsoft.Web.Administration.Site] $site = New-CaccaIISWebsite DeleteMeSite -PassThru -Force
$root = $site.Applications['/'].VirtualDirectories['/']

# New-Item $childPath, $child2Path  -ItemType Directory -Force | Out-Null
Start-IISCommitDelay
New-CaccaIISWebApp $testSiteName MyApp
$app = $site.Applications.Add('/MyApp1', $childPath)
$app.ApplicationPoolName = $testAppPoolName
$app2 = $site.Applications.Add('/MyApp2', $child2Path)
$app2.ApplicationPoolName = $testAppPoolName
Stop-IISCommitDelay
icacls ("$childPath") /grant:r ("$testAppPoolUsername" + ':(OI)(CI)R') | Out-Null
icacls ("$child2Path") /grant:r ("$testAppPoolUsername" + ':(OI)(CI)R') | Out-Null
Reset-IISServerManager -Confirm:$false

$subFolder = Join-Path $childPath 'SubPath1'
New-Item $subFolder -ItemType Directory -Force | Out-Null
icacls ("$subFolder") /grant:r ("$testAppPoolUsername" + ':(OI)(CI)R') | Out-Null

# New-CaccaIISWebsite 'Scrap'
# New-CaccaIISWebsite 'Scrap2' 'C:\inetpub\sites\Scrap\Scrap2' -Port 864 -AppPoolName 'Scrap-AppPool'

Get-CaccaIISSiteAclPath 'Scrap' -Recurse

return

Reset-IISServerManager -Confirm:$false
Remove-CaccaIISWebSite DeleteMeSite -WhatIf

Get-CaccaTempAspNetFilesPaths |  Get-Item -PV pathInfo | % {
    (Get-Item $_.FullName).GetAccessControl('Access').Access.IdentityReference | select -Unique
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

Get-CaccaTempAspNetFilesPaths | % {
    $acl = (Get-Item $_.Path).GetAccessControl('Access')
    $acl.Access | 
        Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $IdentityReference } -EA Ignore |
        ForEach-Object { $acl.RemoveAccessRuleAll($_) }
    Set-Acl -Path ($_.Path) -AclObject $acl
    
}

