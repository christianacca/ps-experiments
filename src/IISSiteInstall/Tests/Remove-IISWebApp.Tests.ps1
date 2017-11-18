$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite5'
$testAppPoolName = "$testSiteName-AppPool"
$testAppPoolUsername = "IIS AppPool\$testSiteName-AppPool"

Describe 'Remove-IISWebApp' {

    function GetAppPoolPermission {
        param(
            [string] $Path,
            [string] $Username
        )
        (Get-Item $Path).GetAccessControl('Access').Access |
            Where-Object { $_.IsInherited -eq $false -and $_.IdentityReference -eq $Username }
    }

    BeforeAll {
        Reset-IISServerManager -Confirm:$false
        # given
        $sitePath = "$TestDrive\$testSiteName"
        New-CaccaIISWebsite $testSiteName $sitePath -AppPoolName $testAppPoolName -Force
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

            # when
            Remove-CaccaIISWebApp $testSiteName $appName
        }

        It 'Should remove existing app' {
            # then
            Get-IISSite $testSiteName | select -Exp Applications | ? Path -eq "/$appName" | Should -BeNullOrEmpty
        }

        It 'Should NOT remove site apppool' {
            # then
            Get-IISAppPool $testAppPoolName | Should -Not -BeNullOrEmpty
        }

        It 'Should remove file permissions to Web app path' {
            # then
            GetAppPoolPermission "$sitePath\$appName" $testAppPoolUsername | Should -BeNullOrEmpty
        }

        It 'Should NOT remove file permissions to Temp ASP.Net files folder' {
            # then
            Get-CaccaTempAspNetFilesPaths | % {
                GetAppPoolPermission $_ $testAppPoolUsername | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Non-Shared app pool' {
        
        BeforeAll {
            # given
            $appPoolName = 'NonSharedPool'
            $appPoolUsername = "IIS AppPool\$appPoolName"
            $appName = 'MyApp'
            New-CaccaIISWebApp $testSiteName $appName -AppPoolName $appPoolName
        
            # when
            Remove-CaccaIISWebApp $testSiteName $appName
        }
        
        It 'Should remove existing app' {
            # then
            Get-IISSite $testSiteName | select -Exp Applications | ? Path -eq "/$appName" | Should -BeNullOrEmpty
        }
        
        It 'Should remove apppool' {
            # then
            Get-IISAppPool $appPoolName -WA SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Should remove file permissions to Web app path' {
            # then
            GetAppPoolPermission "$sitePath\$appName" $appPoolUsername | Should -BeNullOrEmpty
        }

        It 'Should remove file permissions to Temp ASP.Net files folder' {
            # then
            Get-CaccaTempAspNetFilesPaths | % {
                GetAppPoolPermission $_ $appPoolUsername | Should -BeNullOrEmpty
            }
        }
    }
}