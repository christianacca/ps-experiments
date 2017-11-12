$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

. "$PSScriptRoot\Compare-ObjectProperties.ps1"

$testSiteName = 'DeleteMeSite'
$test2SiteName = 'DeleteMeSite2'
$tempAppPool = "$testSiteName-AppPool"


Describe 'Get-IISSiteHierarchyInfo' {

    function Cleanup {
        Reset-IISServerManager -Confirm:$false
        Start-IISCommitDelay
        Remove-IISSite $testSiteName -EA Ignore -Confirm:$false -WA SilentlyContinue
        Remove-IISSite $test2SiteName -EA Ignore -Confirm:$false -WA SilentlyContinue
        $manager = Get-IISServerManager
        $info = $manager.ApplicationPools[$tempAppPool]
        if ($info) {
            $manager.ApplicationPools.Remove($info) 
        }
        Stop-IISCommitDelay
        Reset-IISServerManager -Confirm:$false
    }

    Context 'Site only' {

        BeforeAll {
            New-CaccaIISWebsite $testSiteName $TestDrive -Force
        }

        AfterAll {
            Cleanup
        }

        It 'Should return site app pool' {
            # when
            $info = Get-CaccaIISSiteHierarchyInfo $testSiteName

            # then
            $pool = Get-IISAppPool $tempAppPool
            $expected = [PsCustomObject]@{
                Site_Name            = $testSiteName
                App_Path             = '/'
                App_PhysicalPath     = $TestDrive
                AppPool_Name         = $tempAppPool
                AppPool_IdentityType = $pool.ProcessModel.IdentityType
                AppPool_Username     = $pool.ProcessModel.UserName
            }
            ($info | Measure-Object).Count | Should -Be 1
            Compare-ObjectProperties $info $expected | Should -Be $null
        }
    }

    Context 'All sites' {
        
        BeforeAll {
            New-CaccaIISWebsite $testSiteName $TestDrive -Force
            New-CaccaIISWebsite $test2SiteName $TestDrive -Force -Port 1111
        }
        
        AfterAll {
            Cleanup
        }
        
        It 'Should return info for all sites' {
            # when
            $info = Get-CaccaIISSiteHierarchyInfo
        
            # then
            ($info | Measure-Object).Count | Should -BeGreaterThan 1
            $info | ? Site_Name -eq $testSiteName | Should -Not -BeNullOrEmpty
            $info | ? Site_Name -eq $test2SiteName | Should -Not -BeNullOrEmpty
        }
    }

    Context "Site and child app" {

        BeforeAll {

            [Microsoft.Web.Administration.Site] $site = New-CaccaIISWebsite $testSiteName $TestDrive -Force -PassThru
            Start-IISCommitDelay
            $app = $site.Applications.Add('/MyApp1', (Join-Path $TestDrive 'MyApp1'))
            $app.ApplicationPoolName = $tempAppPool
            Stop-IISCommitDelay
            Reset-IISServerManager -Confirm:$false
        }

        AfterAll {
            Cleanup
        }

        It 'Should return site and child app pool' {
            # when
            $info = Get-CaccaIISSiteHierarchyInfo $testSiteName
            
            # then
            $pool = Get-IISAppPool $tempAppPool
            $expected = @(
                [PsCustomObject]@{
                    Site_Name            = $testSiteName
                    App_Path             = '/'
                    App_PhysicalPath     = $TestDrive
                    AppPool_Name         = $tempAppPool
                    AppPool_IdentityType = $pool.ProcessModel.IdentityType
                    AppPool_Username     = $pool.ProcessModel.UserName
                },
                [PsCustomObject]@{
                    Site_Name            = $testSiteName
                    App_Path             = '/MyApp1'
                    App_PhysicalPath     = (Join-Path $TestDrive 'MyApp1')
                    AppPool_Name         = $tempAppPool
                    AppPool_IdentityType = $pool.ProcessModel.IdentityType
                    AppPool_Username     = $pool.ProcessModel.UserName
                }
            )
            ($info | Measure-Object).Count | Should -Be 2
            Compare-ObjectProperties $info[0] $expected[0] | Should -Be $null
            Compare-ObjectProperties $info[1] $expected[1] | Should -Be $null
        }
    }
}