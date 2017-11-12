$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$testAppPoolName = "$testSiteName-AppPool"
$sitePath = "C:\inetpub\sites\$testSiteName"
$tempSitePath = "$Env:TEMP\$testSiteName"
$appPoolNames = [System.Collections.ArrayList]::new()

function Cleanup {
    Start-IISCommitDelay
    Remove-IISSite $testSiteName -EA Ignore -Confirm:$false -WA SilentlyContinue
    $manager = Get-IISServerManager
    foreach ($poolName in $script:appPoolNames) {
        $pool = $manager.ApplicationPools[$poolName]
        if ($pool) {
            $manager.ApplicationPools.Remove($pool) 
        }
    }
    Stop-IISCommitDelay
    Reset-IISServerManager -Confirm:$false
    Remove-Item $tempSitePath -Recurse -Confirm:$false -EA Ignore
    Remove-Item $sitePath -Recurse -Confirm:$false -EA Ignore
}

function RegisterAppPoolCleanup ([string] $Name) {
    $script:appPoolNames.Add($Name)
}

Describe 'New-IISWebsite' {
    BeforeEach {
        $Script:appPoolNames.Clear()
        RegisterAppPoolCleanup $testAppPoolName
        Cleanup
    }

    AfterEach {
        Cleanup
    }

    It "-Path" {
        # when
        New-CaccaIISWebsite $testSiteName $tempSitePath

        # then
        [Microsoft.Web.Administration.Site] $site = Get-IISSite $testSiteName
        $site | Should -Not -BeNullOrEmpty
        $binding = $site.Bindings[0]
        $binding.Protocol | Should -Be 'http'
        $binding.EndPoint.Port | Should -Be 80
        $site.Applications["/"].ApplicationPoolName | Should -Be $testAppPoolName
        $site.Applications["/"].VirtualDirectories["/"].PhysicalPath | Should -Be $tempSitePath
        $identities = (Get-Acl $tempSitePath).Access.IdentityReference
        $identities | ? Value -eq "IIS AppPool\$testAppPoolName" | Should -Not -BeNullOrEmpty
    }

    It "No Path" {
        # when
        New-CaccaIISWebsite $testSiteName

        # then
        [Microsoft.Web.Administration.Site] $site = Get-IISSite $testSiteName
        $site | Should -Not -BeNullOrEmpty
        $site.Applications["/"].VirtualDirectories["/"].PhysicalPath | Should -Be $sitePath
    }

    It "-SiteConfig" {
        # given
        [Microsoft.Web.Administration.Site] $siteArg = $null
        $siteConfig = {
            $siteArg = $_
        }

        # when
        $site = New-CaccaIISWebsite $testSiteName -SiteConfig $siteConfig -PassThru

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
        RegisterAppPoolCleanup 'MyAppPool'

        # when
        New-CaccaIISWebsite $testSiteName -AppPoolName 'MyAppPool'

        # then
        [Microsoft.Web.Administration.Site] $site = Get-IISSite $testSiteName
        $site | Should -Not -BeNullOrEmpty
        $site.Applications["/"].ApplicationPoolName | Should -Be 'MyAppPool'
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

    It "Site returned by -PassThru should be modifiable" {
        # given
        $otherPath = "TestDrive:\SomeFolder"
        New-Item $otherPath -ItemType Directory

        # when
        [Microsoft.Web.Administration.Site] $site = New-CaccaIISWebsite $testSiteName -PassThru

        Start-IISCommitDelay
        $site.Applications['/'].VirtualDirectories['/'].PhysicalPath = $otherPath
        Stop-IISCommitDelay

        # then
        (Get-IISSite $testSiteName).Applications.VirtualDirectories.PhysicalPath | Should -Be $otherPath
    }

    It "Pipeline property binding" {
        RegisterAppPoolCleanup 'MyApp3'

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
}