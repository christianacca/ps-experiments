$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$testAppPoolName = 'DeleteMeSite-AppPool'

Describe 'Get-IISSiteAclPath' {
    Context 'Site only' {
        BeforeAll {
            New-CaccaIISWebsite $testSiteName $TestDrive -SiteShellOnly -Force
        }

        AfterAll {
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false
        }

        It 'Should return physical path of site' {
            # when
            $paths = Get-CaccaIISSiteAclPath $testSiteName | select -First 1

            # then
            $expected = @($TestDrive.ToString())
            $paths | Should -Be $expected
        }

        It 'Should return physical path of ASP.Net temp folder' {
            # when
            $paths = Get-CaccaIISSiteAclPath $testSiteName | select -Skip 1
            
            # then
            $expected = Get-CaccaTempAspNetFilesPaths
            $paths | Should -Be $expected
        }
    }

    Context 'Site with no-direct AppPool permission' {
        BeforeAll {
            New-CaccaIISWebsite $testSiteName $TestDrive -Force

            # remove AppPoolIdentity user permissions from site path
            $acl = (Get-Item $TestDrive).GetAccessControl('Access')
            $acl.Access | 
                Where-Object IdentityReference -eq "IIS AppPool\$testAppPoolName" |
                ForEach-Object { $acl.RemoveAccessRuleAll($_) }
            Set-Acl -Path $TestDrive -AclObject $acl
        }

        AfterAll {
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false
        }

        It 'Should NOT return physical path of site' {
            
        }
    }

    Context 'Site + 1 child app' {
        BeforeAll {
            [Microsoft.Web.Administration.Site] $site = New-CaccaIISWebsite $testSiteName $TestDrive -Force -PassThru
            Start-IISCommitDelay
            $app = $site.Applications.Add('/MyApp1', (Join-Path $TestDrive 'MyApp1'))
            $app.ApplicationPoolName = $testAppPoolName
            Stop-IISCommitDelay
            Reset-IISServerManager -Confirm:$false
        }

        AfterAll {
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false
        }

        It 'Should return physical path of site' {
            
        }

        It 'Should return physical path of child app' {
            
        }

        It 'Should return physical path of ASP.Net temp folder' {
            
        }
    }

    Context 'Site + 2 child apps' {
        BeforeAll {
            [Microsoft.Web.Administration.Site] $site = New-CaccaIISWebsite $testSiteName $TestDrive -Force -PassThru
            Start-IISCommitDelay
            $app = $site.Applications.Add('/MyApp1', (Join-Path $TestDrive 'MyApp1'))
            $app.ApplicationPoolName = $testAppPoolName
            $app2 = $site.Applications.Add('/MyApp2', (Join-Path $TestDrive 'MyApp2'))
            $app2.ApplicationPoolName = $testAppPoolName
            Stop-IISCommitDelay
            Reset-IISServerManager -Confirm:$false
        }

        AfterAll {
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false
        }

        It 'Should return physical path of site' {
            
        }

        It 'Should return physical path of child app' {
            
        }

        It 'Should return physical path of 2nd child app' {
            
        }

        It 'Should return physical path of ASP.Net temp folder' {
            
        }
    }
}