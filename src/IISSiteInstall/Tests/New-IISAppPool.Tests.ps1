$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$tempAppPool = 'TestAppPool'

Describe 'New-IISAppPool' {

    Context 'App pool does not already exist' {
        BeforeEach {
            Get-IISAppPool $tempAppPool -WA SilentlyContinue | Remove-CaccaIISAppPool
            Reset-IISServerManager -Confirm:$false
        }
    
        AfterEach {
            Get-IISAppPool $tempAppPool | Remove-CaccaIISAppPool
            Reset-IISServerManager -Confirm:$false
        }
    
        It "Can create with sensible defaults" {
    
            # when
            New-CaccaIISAppPool $tempAppPool
    
            # then
            Reset-IISServerManager -Confirm:$false
            [Microsoft.Web.Administration.ApplicationPool] $pool = Get-IISAppPool $tempAppPool
            $pool.Enable32BitAppOnWin64 | Should -Be $true
            $pool.Name | Should -Be $tempAppPool
        }
    
        It "Can override defaults in config script block" {
            
            # when
            New-CaccaIISAppPool $tempAppPool -Config {
                $_.Enable32BitAppOnWin64 = $false
            }
            
            # then
            Reset-IISServerManager -Confirm:$false
            (Get-IISAppPool $tempAppPool).Enable32BitAppOnWin64 | Should -Be $false
        }
    
        It "Can create with specific -AppPoolIdentity" {
            # given
            New-LocalUser 'PesterTestUser' -Password (ConvertTo-SecureString '(pe$ter4powershell)' -AsPlainText -Force)
    
            try {
                # when
                New-CaccaIISAppPool $tempAppPool 'PesterTestUser'
            
                # then
                Reset-IISServerManager -Confirm:$false
                Get-IISAppPool $tempAppPool | Get-CaccaIISAppPoolUsername | Should -Be 'PesterTestUser'
            }
            finally {
                # cleanup
                Remove-LocalUser 'PesterTestUser'
            }
        }
    }

    Context 'App pool already exists' {

        BeforeEach {
            Reset-IISServerManager -Confirm:$false
            New-CaccaIISWebsite $testSiteName $TestDrive -AppPoolName $tempAppPool -Force -AppPoolConfig {
                $_.Enable32BitAppOnWin64 = $false
            }
        }

        AfterEach {
            Reset-IISServerManager -Confirm:$false
            Remove-CaccaIISWebsite $testSiteName -WA SilentlyContinue -Confirm:$false
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