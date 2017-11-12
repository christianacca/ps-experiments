$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$test2SiteName = 'DeleteMeSite2'
$tempAppPool = "$testSiteName-AppPool"
$temp2AppPool = "$test2SiteName-AppPool"
$childAppPool = "MyApp-AppPool"


Describe 'Remove-IISWebsite' {

    function Cleanup {
        Reset-IISServerManager -Confirm:$false
        Start-IISCommitDelay
        Remove-IISSite $testSiteName -EA Ignore -Confirm:$false -WA 'Ignore'
        Remove-IISSite $test2SiteName -EA Ignore -Confirm:$false -WA 'Ignore'
        @($tempAppPool, $temp2AppPool, $childAppPool) | Remove-CaccaIISAppPool -Commit:$false -Force -EA Ignore
        Stop-IISCommitDelay
        Reset-IISServerManager -Confirm:$false
    }

    Context "Site only" {

        BeforeEach {
            Cleanup
            New-CaccaIISWebsite $testSiteName $TestDrive -AppPoolName $tempAppPool
        }

        It 'Should remove site and app pool' {
            # when
            Remove-CaccaIISWebsite $testSiteName

            # then
            Reset-IISServerManager -Confirm:$false
            Get-IISSite $testSiteName -WA Ignore | Should -BeNullOrEmpty
            Get-IISAppPool $tempAppPool -WA Ignore | Should -BeNullOrEmpty
        }

        It '-WhatIf should make no modifications' {
            # when
            Remove-CaccaIISWebsite $testSiteName -WhatIf

            # then
            Get-IISSite $testSiteName | Should -Not -BeNullOrEmpty
            Get-IISAppPool $tempAppPool | Should -Not -BeNullOrEmpty
        }

        It 'ServerManager should be reset after delete' {
            # when
            Remove-CaccaIISWebsite $testSiteName

            New-IISSite $testSiteName $TestDrive '*:2222:' -Passthru | Should -Not -BeNullOrEmpty
        }

    }

    Context "Site and child app" {

        BeforeAll {
            Cleanup

            [Microsoft.Web.Administration.Site] $site = New-CaccaIISWebsite $testSiteName $TestDrive -Force -PassThru
            Start-IISCommitDelay
            New-CaccaIISAppPool $childAppPool -Commit:$false
            $app = $site.Applications.Add('/MyApp1', (Join-Path $TestDrive 'MyApp1'))
            $app.ApplicationPoolName = $childAppPool
            Stop-IISCommitDelay
            Reset-IISServerManager -Confirm:$false
        }

        It 'Should remove site and site and child app pool' {
            # when
            Remove-CaccaIISWebsite $testSiteName
            
            # then
            Get-IISSite $testSiteName -WA Ignore | Should -BeNullOrEmpty
            Get-IISAppPool $tempAppPool -WA Ignore | Should -BeNullOrEmpty
            Get-IISAppPool $childAppPool -WA Ignore | Should -BeNullOrEmpty
        }
    }

    Context "Site and child app - shared app pool" {
        
        BeforeAll {
            Cleanup
            New-CaccaIISWebsite $test2SiteName (Join-Path $TestDrive 'Site2') -Force -Port 3564

            [Microsoft.Web.Administration.Site] $site = New-CaccaIISWebsite $testSiteName $TestDrive -AppPoolName $temp2AppPool -Force -PassThru
            Start-IISCommitDelay
            $app = $site.Applications.Add('/MyApp1', (Join-Path $TestDrive 'MyApp1'))
            $app.ApplicationPoolName = $temp2AppPool
            Stop-IISCommitDelay
            Reset-IISServerManager -Confirm:$false
        }

        AfterAll {
            Cleanup
        }
        
        It 'Should remove site except share app pool' {
            # when
            Remove-CaccaIISWebsite $testSiteName
                    
            # then
            Get-IISSite $testSiteName -WA Ignore | Should -BeNullOrEmpty
            Get-IISAppPool $tempAppPool -WA Ignore | Should -BeNullOrEmpty
            Get-IISAppPool $temp2AppPool | Should -Not -BeNullOrEmpty
        }
    }
}