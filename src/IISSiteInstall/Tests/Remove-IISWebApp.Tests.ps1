$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$testAppPoolName = "$testSiteName-AppPool"

Describe 'Remove-IISWebApp' {

    BeforeAll {
        # given
        $sitePath = "$TestDrive\$testSiteName"
        New-CaccaIISWebsite $testSiteName $sitePath -Force -AppPoolName $testAppPoolName
    }

    AfterAll {
        Remove-CaccaIISWebsite $testSiteName -Confirm:$false
    }

    It 'Should not throw if website does not exist' {
        { Remove-CaccaIISWebApp NonExistantSite MyApp -EA Stop; $true } | Should -Be $true
    }

    It 'Should not throw if web app does not exist' {
        { Remove-CaccaIISWebApp $testSiteName NonExistantApp -EA Stop; $true } | Should -Be $true
    }

    Context 'App shares app pool of site' {

        BeforeAll {
            # given
            $appName = 'MyApp'
            New-CaccaIISWebApp $testSiteName $appName
            Reset-IISServerManager -Confirm:$false

            # when
            Remove-CaccaIISWebApp $testSiteName $appName

            # Reset-IISServerManager -Confirm:$false
        }

        It 'Should remove existing app' {
            # then
            Get-IISSite $testSiteName | select -Exp Applications | ? Path -eq "/$appName" | Should -BeNullOrEmpty
        }

        It 'Should NOT remove site apppool' {
            # then
            Get-IISAppPool $testAppPoolName | Should -Not -BeNullOrEmpty
        }

        # It 'ServerManager should be reset after delete' {
        #     # then
        #     # note: this will throw if the ServerManager was NOT refreshed
        #     New-CaccaIISWebApp $testSiteName $appName -Passthru | Should -Not -BeNullOrEmpty
        # }
    }

    Context 'Non-Shared app pool' {
        
        BeforeAll {
            # given
            $appPoolName = 'NonSharedPool'
            $appName = 'MyApp'
            Start-IISCommitDelay
            New-CaccaIISAppPool $appPoolName -Force -Commit:$false
            New-CaccaIISWebApp $testSiteName $appName -AppPoolName $appPoolName -Commit:$false
            Stop-IISCommitDelay
            Reset-IISServerManager -Confirm:$false
        
            # when
            Remove-CaccaIISWebApp $testSiteName $appName

            Reset-IISServerManager -Confirm:$false
        }
        
        It 'Should remove existing app' {
            # then
            Get-IISSite $testSiteName | select -Exp Applications | ? Path -eq "/$appName" | Should -BeNullOrEmpty
        }
        
        It 'Should remove apppool' {
            # then
            Get-IISAppPool $appPoolName -WA SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}