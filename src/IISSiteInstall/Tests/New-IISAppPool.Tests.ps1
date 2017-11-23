$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$tempAppPool = 'TestAppPool'

Describe 'New-IISAppPool' {

    Context 'App pool does not already exist' {
        BeforeEach {
            $testLocalUser = 'PesterTestUser'
            $domainQualifiedTestLocalUser = "$($env:COMPUTERNAME)\$testLocalUser"
            Get-IISAppPool $tempAppPool -WA SilentlyContinue | Remove-CaccaIISAppPool
            # Reset-IISServerManager -Confirm:$false
        }
    
        AfterEach {
            Get-IISAppPool $tempAppPool | Remove-CaccaIISAppPool
            Get-LocalUser $testLocalUser -EA SilentlyContinue | Remove-LocalUser
            # Reset-IISServerManager -Confirm:$false
        }
    
        It "Can create with sensible defaults" {
    
            # when
            New-CaccaIISAppPool $tempAppPool
    
            # then
            # Reset-IISServerManager -Confirm:$false
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
            # Reset-IISServerManager -Confirm:$false
            (Get-IISAppPool $tempAppPool).Enable32BitAppOnWin64 | Should -Be $false
        }
    
        It "Can create with specific user account" {
            # given
            $pswd = ConvertTo-SecureString '(pe$ter4powershell)' -AsPlainText -Force
            $creds = [PsCredential]::new($domainQualifiedTestLocalUser, $pswd)
            New-LocalUser $testLocalUser -Password $pswd
    
            # when
            New-CaccaIISAppPool $tempAppPool $creds
            
            # then
            # Reset-IISServerManager -Confirm:$false
            Get-IISAppPool $tempAppPool | Get-CaccaIISAppPoolUsername | Should -Be $domainQualifiedTestLocalUser
        }
    }

    Context 'App pool already exists' {

        BeforeEach {
            # Reset-IISServerManager -Confirm:$false
            New-CaccaIISWebsite $testSiteName $TestDrive -AppPoolName $tempAppPool -Force -AppPoolConfig {
                $_.Enable32BitAppOnWin64 = $false
            }
        }

        AfterEach {
            # Reset-IISServerManager -Confirm:$false
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
            # Reset-IISServerManager -Confirm:$false
            (Get-IISAppPool $tempAppPool).Enable32BitAppOnWin64 | Should -Be $true
        }

        It 'Replaced pool should still be associated with existing site' {
            # when
            New-CaccaIISAppPool $tempAppPool -Force -Config {
                $_.Enable32BitAppOnWin64 = $true
            }
            
            # then
            # Reset-IISServerManager -Confirm:$false
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