$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$test2SiteName = 'DeleteMeSite2'
$tempAppPool = "$testSiteName-AppPool"
$tempAppPoolUsername = "IIS AppPool\$testSiteName-AppPool"
$temp2AppPool = "$test2SiteName-AppPool"
$childAppPool = "MyApp-AppPool"


Describe 'Remove-IISWebsite' {

    function Cleanup {
        Reset-IISServerManager -Confirm:$false
        Start-IISCommitDelay
        Remove-IISSite $testSiteName -EA Ignore -Confirm:$false -WA SilentlyContinue
        Remove-IISSite $test2SiteName -EA Ignore -Confirm:$false -WA SilentlyContinue
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
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false

            # then
            Reset-IISServerManager -Confirm:$false
            Get-IISSite $testSiteName -WA SilentlyContinue | Should -BeNullOrEmpty
            Get-IISAppPool $tempAppPool -WA SilentlyContinue | Should -BeNullOrEmpty
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
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false

            New-IISSite $testSiteName $TestDrive '*:2222:' -Passthru | Should -Not -BeNullOrEmpty
        }

        It 'Should remove App pool file permissions' {
            # checking assumptions
            $getAppPoolPermissions = {
                (Get-Item $TestDrive).GetAccessControl('Access').Access |
                Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $tempAppPoolUsername }
            }

            & $getAppPoolPermissions | Should -Not -BeNullOrEmpty

            # when
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false

            # then
            & $getAppPoolPermissions | Should -BeNullOrEmpty
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
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false
            
            # then
            Get-IISSite $testSiteName -WA SilentlyContinue | Should -BeNullOrEmpty
            Get-IISAppPool $tempAppPool -WA SilentlyContinue | Should -BeNullOrEmpty
            Get-IISAppPool $childAppPool -WA SilentlyContinue | Should -BeNullOrEmpty
        }
    }

    Context "Site and child app - shared app pool" {

        BeforeAll {

            Cleanup
            New-CaccaIISWebsite $test2SiteName "$TestDrive\Site2" -AppPoolName $temp2AppPool -Force -Port 3564

            [Microsoft.Web.Administration.Site] $site = New-CaccaIISWebsite $testSiteName $TestDrive -Force -PassThru
            Start-IISCommitDelay
            $app = $site.Applications.Add('/MyApp1', "$TestDrive\MyApp1")
            $app.ApplicationPoolName = $temp2AppPool
            Stop-IISCommitDelay
            Reset-IISServerManager -Confirm:$false
        }

        AfterAll {
            Cleanup
        }
        
        It 'Should remove site except share app pool' {
            # when
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false
                    
            # then
            Get-IISSite $testSiteName -WA SilentlyContinue | Should -BeNullOrEmpty
            Get-IISAppPool $tempAppPool -WA SilentlyContinue | Should -BeNullOrEmpty
            Get-IISAppPool $temp2AppPool | Should -Not -BeNullOrEmpty
        }
    }
}