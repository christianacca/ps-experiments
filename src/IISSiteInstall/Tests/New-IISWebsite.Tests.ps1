$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$testAppPoolName = "$testSiteName-AppPool"
$sitePath = "C:\inetpub\sites\$testSiteName"
$tempSitePath = "$Env:TEMP\$testSiteName"

function Cleanup {
    Remove-IISSite $testSiteName -EA Ignore -Confirm:$false -WarningAction 'Ignore'
    Remove-Item $tempSitePath -Recurse -Confirm:$false -EA Ignore
    Remove-Item $sitePath -Recurse -Confirm:$false -EA Ignore
}

Describe "New-IISWebsite" {
    BeforeEach {
        Reset-IISServerManager -Confirm:$false -WarningAction 'Ignore'
        Cleanup
    }

    AfterAll {
        Cleanup
    }

    It "-Path" {
        # when
        New-CaccaIISWebsite $testSiteName $tempSitePath

        # then
        Reset-IISServerManager -Confirm:$false # make sure to read from saved settings
        [Microsoft.Web.Administration.Site] $site = Get-IISSite $testSiteName
        $site | Should -Not -BeNullOrEmpty
        $binding = $site.Bindings[0]
        $binding.Protocol | Should -Be 'http'
        $binding.EndPoint.Port | Should -Be 80
        $site.Applications["/"].ApplicationPoolName | Should -Be 'DeleteMeSite-AppPool'
        $site.Applications["/"].VirtualDirectories["/"].PhysicalPath | Should -Be $tempSitePath
        $identities = (Get-Acl $tempSitePath).Access.IdentityReference
        $identities | ? Value -eq 'IIS AppPool\DeleteMeSite-AppPool' | Should -Not -BeNullOrEmpty
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
        $siteArg = $null
        $siteConfig = {
            $siteArg = $_
        }

        # when
        $site = New-CaccaIISWebsite $testSiteName -SiteConfig $siteConfig -PassThru

        # then
        $siteArg | Should -Be $site
    }

    It "-HostName" {
        # when
        New-CaccaIISWebsite $testSiteName -HostName 'local-site'

        # then
        [Microsoft.Web.Administration.Site] $site = Get-IISSite $testSiteName
        $site | Should -Not -BeNullOrEmpty
        $site.Bindings[0].Host | Should -Be 'local-site'
        $site.Applications["/"].ApplicationPoolName | Should -Be 'local-site-AppPool'
    }

    It "Pipeline property binding" -Skip {
        # given
        $siteParams = @{
            SiteName = $testSiteName
            Path     = $tempSitePath
            Port = 80
            Protocol = 'http'
            HostName = 'local-site'
            SiteConfig = {}
            ModifyPaths = @()
            ExecutePaths = @()
            SiteShellOnly = $true
        }

        # when
        New-CaccaIISWebsite $testSiteName -HostName 'local-site'

        # then
        [Microsoft.Web.Administration.Site] $site = Get-IISSite $testSiteName
        $site | Should -Not -BeNullOrEmpty
        $site.Bindings[0].Host | Should -Be 'local-site'
        $site.Applications["/"].ApplicationPoolName | Should -Be 'local-site-AppPool'
    }

    It '-Commit:$false, transation rolled back' {
        # when
        Start-IISCommitDelay
        New-CaccaIISWebsite $testSiteName $tempSitePath -Commit:$false
        Stop-IISCommitDelay -Commit:$false

        # then
        Reset-IISServerManager -Confirm:$false
        Get-IISSite $testSiteName | Should -Be $null
        # note that file permissions were NOT rolled back (is this a problem?)
        $identities = (Get-Acl $tempSitePath).Access.IdentityReference
        $identities | ? Value -eq 'IIS AppPool\DeleteMeSite-AppPool' | Should -Not -BeNullOrEmpty  
    }

    It '-Commit:$false, transation committed' {
        # when
        Start-IISCommitDelay
        New-CaccaIISWebsite $testSiteName -Commit:$false
        Stop-IISCommitDelay

        # then
        Reset-IISServerManager -Confirm:$false
        Get-IISSite $testSiteName | Should -Not -Be $null
    }
}