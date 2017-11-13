$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

. "$PSScriptRoot\Compare-ObjectProperties.ps1"

$testSiteName = 'DeleteMeSite'
$testAppPoolName = 'DeleteMeSite-AppPool'
$testAppPoolUsername = 'IIS AppPool\DeleteMeSite-AppPool'

Describe 'Get-IISSiteAclPath' {

    BeforeAll {
        $tempAspNetPathCount = Get-CaccaTempAspNetFilesPaths | measure | select -Exp Count
    }

    Context 'Site only' {
        BeforeAll {
            New-CaccaIISWebsite $testSiteName $TestDrive -Force
        }

        AfterAll {
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false
        }

        It 'Should include physical path of site' {
            # when
            $paths = Get-CaccaIISSiteAclPath $testSiteName | select -First 1

            # then
            $expected = [PsCustomObject]@{
                Path              = $TestDrive.ToString()
                IdentityReference = $testAppPoolUsername
            }
            Compare-ObjectProperties $paths $expected | Should -Be $null
        }

        It 'Should include physical path of ASP.Net temp folder' {
            # when
            $paths = Get-CaccaIISSiteAclPath $testSiteName | select -Exp Path -Skip 1
            
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

        It 'Should NOT include physical path of site' {
            # when
            $paths = Get-CaccaIISSiteAclPath $testSiteName | select -Exp Path
            
            # then
            $paths | Should -Not -BeIn @($TestDrive.ToString())
        }
    }

    Context 'Site + 2 child apps' {
        BeforeAll {
            $childPath = "$TestDrive\MyApp1"
            $child2Path = "$TestDrive\MyApp2"

            [Microsoft.Web.Administration.Site] $site = New-CaccaIISWebsite $testSiteName $TestDrive -Force -PassThru
            New-Item $childPath, $child2Path  -ItemType Directory
            Start-IISCommitDelay
            $app = $site.Applications.Add('/MyApp1', $childPath)
            $app.ApplicationPoolName = $testAppPoolName
            $app2 = $site.Applications.Add('/MyApp2', $child2Path)
            $app2.ApplicationPoolName = $testAppPoolName
            Stop-IISCommitDelay
            icacls ("$childPath") /grant:r ("$testAppPoolUsername" + ':(OI)(CI)R') | Out-Null
            icacls ("$child2Path") /grant:r ("$testAppPoolUsername" + ':(OI)(CI)R') | Out-Null
            Reset-IISServerManager -Confirm:$false
        }

        AfterAll {
            Remove-CaccaIISWebsite $testSiteName -Confirm:$false
        }

        It 'Should include physical path of site' {
            # when
            $paths = Get-CaccaIISSiteAclPath $testSiteName | select -First 1
            
            # then
            $expected = [PsCustomObject]@{
                Path              = $TestDrive.ToString()
                IdentityReference = $testAppPoolUsername
            }
            Compare-ObjectProperties $paths $expected | Should -Be $null
        }

        It 'Should include physical path of child apps' {
            # when
            $paths = Get-CaccaIISSiteAclPath $testSiteName | select -Skip 1 -First 2
            
            # then
            $expected = @(
                [PsCustomObject]@{
                    Path              = "$TestDrive\MyApp1"
                    IdentityReference = $testAppPoolUsername
                },
                [PsCustomObject]@{
                    Path              = "$TestDrive\MyApp2"
                    IdentityReference = $testAppPoolUsername
                }
            )
            ($paths | Measure-Object).Count | Should -Be 2
            Compare-ObjectProperties $paths[0] $expected[0] | Should -Be $null
            Compare-ObjectProperties $paths[1] $expected[1] | Should -Be $null
        }

        Context '+ sub-folders' {

            BeforeAll {
                # given
                $subFolder = Join-Path $childPath 'SubPath1'
                $unsecuredSubFolder = Join-Path $childPath 'SubPath1\SubSubPath2'
                New-Item $subFolder -ItemType Directory
                New-Item $unsecuredSubFolder -ItemType Directory
                icacls ("$subFolder") /grant:r ("$testAppPoolUsername" + ':(OI)(CI)R') | Out-Null

                # when
                $paths = Get-CaccaIISSiteAclPath $testSiteName
            }

            It 'Should include paths to secured subfolders' {
                # then
                ($paths | ? Path -eq $subFolder | measure).Count | Should -Be 1
            }

            It 'Should NOT include paths to unsecured subfolders' {
                # then
                ($paths | ? Path -eq $unsecuredSubFolder | measure).Count | Should -Be 0
            }
        }

        Context '+ specific files' {
            
            BeforeAll {
                # given
                New-Item "$childPath\SubPath" -ItemType Directory
                $unsecuredFilePath = (New-Item "$childPath\NotAllowed.exe" -Value 'source code' -Force).FullName
                $securedFilePath = (New-Item "$childPath\SomeProgram.exe" -Value 'source code' -Force).FullName
                $securedFile2Path = (New-Item "$childPath\SubPath\OtherProgram.exe" -Value 'source code' -Force).FullName
                icacls ("$securedFilePath") /grant:r ("$testAppPoolUsername" + ':(RX)') | Out-Null
                icacls ("$securedFile2Path") /grant:r ("$testAppPoolUsername" + ':(RX)') | Out-Null
            
                # when
                $paths = Get-CaccaIISSiteAclPath $testSiteName
            }
            
            It 'Should include paths to secured files' {
                # then
                ($paths | ? Path -eq $securedFilePath | measure).Count | Should -Be 1
                ($paths | ? Path -eq $securedFile2Path | measure).Count | Should -Be 1
            }
            
            It 'Should NOT include paths to unsecured subfolders' {
                # then
                ($paths | ? Path -eq $unsecuredFilePath | measure).Count | Should -Be 0
            }
        }
    }

    Context '+ 2 child apps with different AppPool identities' {
        
        BeforeAll {
            # given
            $childPath = "$TestDrive\MyApp1"
            $child2Path = "$TestDrive\MyApp2"

            New-CaccaIISAppPool 'AnotherPool' -Force
            Reset-IISServerManager -Confirm:$false
            [Microsoft.Web.Administration.Site] $site = New-CaccaIISWebsite $testSiteName $TestDrive -Force -PassThru
            New-Item $childPath, $child2Path  -ItemType Directory
            Start-IISCommitDelay
            $app = $site.Applications.Add('/MyApp1', $childPath)
            $app.ApplicationPoolName = 'AnotherPool'
            $app2 = $site.Applications.Add('/MyApp2', $child2Path)
            $app2.ApplicationPoolName = $testAppPoolName
            Stop-IISCommitDelay
            icacls ("$childPath") /grant:r ("$testAppPoolUsername" + ':(OI)(CI)R') | Out-Null
            icacls ("$child2Path") /grant:r ('IIS AppPool\AnotherPool' + ':(OI)(CI)R') | Out-Null
            Reset-IISServerManager -Confirm:$false
        
            # when
            $paths = Get-CaccaIISSiteAclPath $testSiteName
        }

        AfterAll {
            Remove-CaccaIISWebsite $testSiteName
        }
        
        It 'Should include paths for both AppPool identities' {
            # then
            ($paths | ? IdentityReference -eq $testAppPoolUsername | measure).Count | Should -Be ($tempAspNetPathCount + 2)
            ($paths | ? IdentityReference -eq 'IIS AppPool\AnotherPool' | measure).Count | Should -Be 1
        }
    }
}