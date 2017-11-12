$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$tempAppPool = 'TestAppPool'

Describe 'New-IISAppPool' {

    AfterEach {
        Reset-IISServerManager -Confirm:$false
    }

    It "Can create with sensible defaults" {

        # when
        [Microsoft.Web.Administration.ApplicationPool] $pool = New-CaccaIISAppPool $tempAppPool -PassThru -Commit:$false

        # then
        $pool.Enable32BitAppOnWin64 | Should -Be $true
        $pool.Name | Should -Be $tempAppPool
    }

    It "Can override defaults in config script block" {
        
        # when
        $pool = New-CaccaIISAppPool $tempAppPool -PassThru -Commit:$false -Config {
            $_.Enable32BitAppOnWin64 = $false
        }
        
        # then
        $pool.Enable32BitAppOnWin64 | Should -Be $false
    }

    Context 'App pool already exists' {
        
        function Cleanup {
            Reset-IISServerManager -Confirm:$false
            Remove-CaccaIISWebsite $testSiteName
        }


        BeforeEach {
            Cleanup
            New-CaccaIISWebsite $testSiteName $TestDrive -AppPoolName $tempAppPool -AppPoolConfig {
                $_.Enable32BitAppOnWin64 = $false
            }
        }

        AfterEach {
            Cleanup
        }

        It 'Should throw' {
            {New-CaccaIISAppPool $tempAppPool -EA Stop} | Should Throw
        }

        It '-Force should replace pool' {
            # when
            New-CaccaIISAppPool $tempAppPool -Force -Config {
                $_.Enable32BitAppOnWin64 = $true
            }
            
            # then
            Reset-IISServerManager -Confirm:$false
            (Get-IISAppPool $tempAppPool).Enable32BitAppOnWin64 | Should -Be $true
        }

        It 'Replaced pool should still be associated with existing site' {
            # when
            New-CaccaIISAppPool $tempAppPool -Force -Config {
                $_.Enable32BitAppOnWin64 = $true
            }
            
            # then
            Reset-IISServerManager -Confirm:$false
            [Microsoft.Web.Administration.Site] $site = Get-IISSite $testSiteName
            $site.Applications["/"].ApplicationPoolName | Should -Be $tempAppPool
        }

        It '-WhatIf should make no modifications' {
            # when
            New-CaccaIISAppPool $tempAppPool -Force -WhatIf -Config {
                $_.Enable32BitAppOnWin64 = $true
            }
            
            # then
            (Get-IISAppPool $tempAppPool).Enable32BitAppOnWin64 | Should -Be $false
        }
    }
}