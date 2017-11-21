$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$testAppPoolName = "$testSiteName-AppPool"
$testAppPoolUsername = "IIS AppPool\$testAppPoolName"
$sitePath = "C:\inetpub\sites\$testSiteName"


Describe 'New-IISWebsite' {

    function Cleanup {
        Reset-IISServerManager -Confirm:$false
        $siteToDelete = Get-IISSite $testSiteName -WA SilentlyContinue
        if ($siteToDelete) {
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false
            Remove-Item ($siteToDelete.Applications['/'].VirtualDirectories['/'].PhysicalPath) -Recurse -Confirm:$false
        }
        if (Test-Path $sitePath) {
            Remove-Item $sitePath -Recurse -Confirm:$false
        }
        Get-LocalUser 'PesterTestUser-*' | Remove-LocalUser
    }

    BeforeEach {
        $tempSitePath = "$TestDrive\$testSiteName"
        Cleanup
    }

    AfterEach {
        Cleanup
    }

    It "With defaults" {
        # when
        New-CaccaIISWebsite $testSiteName

        # then
        [Microsoft.Web.Administration.Site] $site = Get-IISSite $testSiteName
        $site | Should -Not -BeNullOrEmpty

        $binding = $site.Bindings[0]
        $binding.Protocol | Should -Be 'http'
        $binding.EndPoint.Port | Should -Be 80

        $appPool = Get-IISAppPool $testAppPoolName
        $appPool | Should -Not -BeNullOrEmpty
        $appPool.Name | Should -Be $testAppPoolName
        $appPool.Enable32BitAppOnWin64 | Should -Be $true
        $appPool | Get-CaccaIISAppPoolUsername | Should -Be $testAppPoolUsername

        $site.Applications['/'].ApplicationPoolName | Should -Be $testAppPoolName
        $site.Applications["/"].VirtualDirectories["/"].PhysicalPath | Should -Be $sitePath

        $checkAccess = {
            $identities = (Get-Acl $_).Access.IdentityReference
            $identities | ? { $_.Value -eq $testAppPoolUsername } | Should -Not -BeNullOrEmpty
        }

        $sitePath | % $checkAccess
        Get-CaccaTempAspNetFilesPaths | % $checkAccess
    }

    It "-Path" {
        # when
        New-CaccaIISWebsite $testSiteName $tempSitePath

        # then
        [Microsoft.Web.Administration.Site] $site = Get-IISSite $testSiteName
        $site | Should -Not -BeNullOrEmpty
        $site.Applications['/'].VirtualDirectories['/'].PhysicalPath | Should -Be $tempSitePath
        $identities = (Get-Acl $tempSitePath).Access.IdentityReference
        $identities | ? Value -eq $testAppPoolUsername | Should -Not -BeNullOrEmpty
    }

    It "-SiteConfig" {
        # given
        [Microsoft.Web.Administration.Site] $siteArg = $null
        $siteConfig = {
            $siteArg = $_
        }

        # when
        $site = New-CaccaIISWebsite $testSiteName -SiteConfig $siteConfig

        # then
        $siteArg | Should -Not -Be $null
        $siteArg.Name | Should -Be ($site.Name)
    }

    It "-HostName" {
        # when
        New-CaccaIISWebsite $testSiteName -HostName 'local-site'

        # then
        [Microsoft.Web.Administration.Site] $site = Get-IISSite $testSiteName
        $site | Should -Not -BeNullOrEmpty
        $site.Bindings[0].Host | Should -Be 'local-site'
    }

    It "-AppPoolName" {
        # when
        New-CaccaIISWebsite $testSiteName -AppPoolName 'MyAppPool'

        # then
        [Microsoft.Web.Administration.Site] $site = Get-IISSite $testSiteName
        $site | Should -Not -BeNullOrEmpty
        $site.Applications["/"].ApplicationPoolName | Should -Be 'MyAppPool'
    }

    It "-AppPoolIdentity" {
        # given
        $testLocalUser = "PesterTestUser-$(Get-Random -Maximum 10000)"
        $domainQualifiedTestLocalUser = "$($env:COMPUTERNAME)\$testLocalUser"
        New-LocalUser $testLocalUser -Password (ConvertTo-SecureString '(pe$ter4powershell)' -AsPlainText -Force)

        # when
        New-CaccaIISWebsite $testSiteName $tempSitePath -AppPoolIdentity $domainQualifiedTestLocalUser -EA Stop
        
        # then
        $appPool = Get-IISAppPool $testAppPoolName
        $appPool | Should -Not -BeNullOrEmpty
        $appPool | Get-CaccaIISAppPoolUsername | Should -Be $domainQualifiedTestLocalUser
        & {
            $tempSitePath
            Get-CaccaTempAspNetFilesPaths
        } | % {
            $identities = (Get-Acl $_).Access.IdentityReference
            $identities | ? { $_.Value -eq $domainQualifiedTestLocalUser } | Should -Not -BeNullOrEmpty
        }        
    }

    It "-AppPoolConfig" {
        # given
        [Microsoft.Web.Administration.ApplicationPool]$pool = $null
        $appPoolConfig = {
            $pool = $_
            $_.ManagedRuntimeVersion = 'v2.0'
        }

        # when
        New-CaccaIISWebsite $testSiteName -AppPoolConfig $appPoolConfig

        # then
        $pool | Should -Not -BeNullOrEmpty
        (Get-IISAppPool $testAppPoolName).ManagedRuntimeVersion | Should -Be 'v2.0'
    }

    It "-SiteShellOnly" {
        # when
        New-CaccaIISWebsite $testSiteName -SiteShellOnly

        # then
        Get-IISSite $testSiteName | Should -Not -BeNullOrEmpty  
        # todo: verify that Set-CaccaIISSiteAcl called with -SiteShellOnly
    }

    It "Site returned should be modifiable" {
        # given
        $otherPath = "TestDrive:\SomeFolder"
        New-Item $otherPath -ItemType Directory

        # when
        [Microsoft.Web.Administration.Site] $site = New-CaccaIISWebsite $testSiteName

        Start-IISCommitDelay
        $site.Applications['/'].VirtualDirectories['/'].PhysicalPath = $otherPath
        Stop-IISCommitDelay

        # then
        (Get-IISSite $testSiteName).Applications.VirtualDirectories.PhysicalPath | Should -Be $otherPath
    }

    It "Pipeline property binding" {
        # given
        $siteParams = @{
            Name          = $testSiteName
            Path          = $tempSitePath
            Port          = 80
            Protocol      = 'http'
            HostName      = 'local-site'
            SiteConfig    = {}
            ModifyPaths   = @()
            ExecutePaths  = @()
            SiteShellOnly = $true
            AppPoolName   = 'MyApp3'
        }

        # when
        New-CaccaIISWebsite @siteParams

        # then
        Get-IISSite $testSiteName | Should -Not -BeNullOrEmpty
    }

    It "-WhatIf should not modify anything" {
        # when
        New-CaccaIISWebsite $testSiteName $tempSitePath -AppPoolName 'MyAppPool' -WhatIf

        # then
        Get-IISSite $testSiteName -WA SilentlyContinue | Should -BeNullOrEmpty
        Get-IISAppPool 'MyAppPool' -WA SilentlyContinue | Should -BeNullOrEmpty
        Test-Path $tempSitePath | Should -Be $false
    }

    It "-WhatIf should not modify anything (site path exists)" {
        # given
        New-Item $sitePath -ItemType Directory -EA Ignore

        # when
        New-CaccaIISWebsite $testSiteName $sitePath -AppPoolName 'MyAppPool' -WhatIf

        # then
        Get-IISSite $testSiteName -WA SilentlyContinue | Should -BeNullOrEmpty
        Get-IISAppPool 'MyAppPool' -WA SilentlyContinue | Should -BeNullOrEmpty
        Test-Path $tempSitePath | Should -Be $false
    }
}