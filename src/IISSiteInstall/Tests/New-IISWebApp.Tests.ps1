$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$testAppPoolName = "$testSiteName-AppPool"

Describe 'New-IISWebApp' {

    BeforeAll {
        # given
        $sitePath = "$TestDrive\$testSiteName"
        New-CaccaIISWebsite $testSiteName $sitePath -Force -AppPoolName $testAppPoolName
    }

    AfterAll {
        Remove-CaccaIISWebsite $testSiteName -Confirm:$false
    }

    Context 'With defaults' {
    
        BeforeAll {
            $appName = 'MyApp'
            # when
            New-CaccaIISWebApp $testSiteName $appName

            Reset-IISServerManager -Confirm:$false
        }
    
        AfterAll {
            Remove-CaccaIISWebApp $testSiteName $appName
            Reset-IISServerManager -Confirm:$false
        }

        It 'Should have created child app' {
            # then
            $site = Get-IISSite $testSiteName
            $site.Applications["/$appName"] | Should -Not -BeNullOrEmpty
        }

        It 'Should set physical path to be a subfolder of site' {
            # then
            $app = (Get-IISSite $testSiteName).Applications["/$appName"]
            $expectedPhysicalPath = "$sitePath\$appName"
            $expectedPhysicalPath | Should -Exist
            $app.VirtualDirectories["/"].PhysicalPath | Should -Be $expectedPhysicalPath
        }

        It 'Should use the site AppPool' {
            # then
            $app = (Get-IISSite $testSiteName).Applications["/$appName"]
            $app.ApplicationPoolName | Should -Be $testAppPoolName
        }
        
        It 'Should assign file permissions to the physical app path' {
            # then
            $physicalPath = (Get-IISSite $testSiteName).Applications["/$appName"].VirtualDirectories["/"].PhysicalPath
            $identities = (Get-Acl $physicalPath).Access.IdentityReference
            $identities | ? Value -eq "IIS AppPool\$testAppPoolName" | Should -Not -BeNullOrEmpty
        }
    }

    Context '-Name' {
        BeforeAll {
            $appName = '/MyApp/Child2'

            # when
            New-CaccaIISWebApp $testSiteName $appName

            Reset-IISServerManager -Confirm:$false
        }
    
        AfterAll {
            Remove-CaccaIISWebApp $testSiteName $appName
            Reset-IISServerManager -Confirm:$false
        }

        It 'Should have created child app with name supplied' {
            # then
            $site = Get-IISSite $testSiteName
            $site.Applications[$appName] | Should -Not -BeNullOrEmpty
        }

        It 'Should set physical path to be a subfolder of site' {
            # then
            $app = (Get-IISSite $testSiteName).Applications[$appName]
            $expectedPhysicalPath = "$sitePath$($appName.Replace('/', '\'))"
            $expectedPhysicalPath | Should -Exist
            $app.VirtualDirectories["/"].PhysicalPath | Should -Be $expectedPhysicalPath
        }
    }

    Context '-Path' {
        BeforeAll {
            # given
            $appName = '/MyApp/BlahBlah'
            $appPhysicalPath = "$TestDrive\SomeOtherPath"

            # when
            New-CaccaIISWebApp $testSiteName $appName $appPhysicalPath

            Reset-IISServerManager -Confirm:$false
        }
    
        AfterAll {
            Remove-CaccaIISWebApp $testSiteName $appName
            Reset-IISServerManager -Confirm:$false
        }

        It 'Should use physical path supplied' {
            # then
            $app = (Get-IISSite $testSiteName).Applications[$appName]
            $appPhysicalPath | Should -Exist
            $app.VirtualDirectories["/"].PhysicalPath | Should -Be $appPhysicalPath
        }
    }

    Context '-Path already exists' {
        BeforeAll {
            # given
            $appName = '/MyApp/Child2'
            $appPhysicalPath = "$TestDrive\ExistingPath"
            New-Item $appPhysicalPath -ItemType Directory -Force

            # when
            New-CaccaIISWebApp $testSiteName $appName $appPhysicalPath

            Reset-IISServerManager -Confirm:$false
        }
    
        AfterAll {
            Remove-CaccaIISWebApp $testSiteName $appName
            Reset-IISServerManager -Confirm:$false
        }

        It 'Should use physical path supplied' {
            # then
            $app = (Get-IISSite $testSiteName).Applications[$appName]
            $app.VirtualDirectories["/"].PhysicalPath | Should -Be $appPhysicalPath
        }
    }

    Context '-AppPoolName, when pool exists' {
        BeforeAll {
            # given
            $appPoolName = 'NonSharedPool'
            New-CaccaIISAppPool $appPoolName -Force -Config {
                $_.Enable32BitAppOnWin64 = $false
                $_.AutoStart = $false
            }
            Reset-IISServerManager -Confirm:$false
            $appName = '/MyApp'

            # when
            New-CaccaIISWebApp $testSiteName $appName -AppPoolName $appPoolName

            Reset-IISServerManager -Confirm:$false
        }
    
        AfterAll {
            Remove-CaccaIISWebApp $testSiteName $appName
            Reset-IISServerManager -Confirm:$false
        }

        It 'Should assign existing pool supplied' {
            # then
            $app = (Get-IISSite $testSiteName).Applications[$appName]
            $app.ApplicationPoolName | Should -Be $appPoolName
        }

        It 'Should not replace existing pool' {
            # then
            $pool = Get-IISAppPool $appPoolName
            $pool.Enable32BitAppOnWin64 | Should -Be $false
            $pool.AutoStart | Should -Be $false
        }
    }

    Context '-AppPoolName, when pool does NOT exist' {
        BeforeAll {
            # given
            $appPoolName = 'NonSharedPool86'
            $appName = '/MyApp'

            # when
            New-CaccaIISWebApp $testSiteName $appName -AppPoolName $appPoolName

            Reset-IISServerManager -Confirm:$false
        }
    
        AfterAll {
            Remove-CaccaIISWebApp $testSiteName $appName
            Reset-IISServerManager -Confirm:$false
        }

        It 'Should create new pool' {
            # then
            Get-IISAppPool $appPoolName | Should -Not -BeNullOrEmpty
        }

        It 'Should assign new pool to Web application' {
            # then
            $app = (Get-IISSite $testSiteName).Applications[$appName]
            $app.ApplicationPoolName | Should -Be $appPoolName
        }
    }

    Context '-AppPoolConfig, when pool exists' {
        BeforeAll {
            # given
            $appPoolName = 'Pool789'
            New-CaccaIISAppPool $appPoolName -Force -Config {
                $_.Enable32BitAppOnWin64 = $false
                $_.AutoStart = $false
            }
            Reset-IISServerManager -Confirm:$false
            $appName = '/MyApp'

            # when
            New-CaccaIISWebApp $testSiteName $appName -AppPoolName $appPoolName -AppPoolConfig {
                $_.AutoStart = $true
            }

            Reset-IISServerManager -Confirm:$false
        }
    
        AfterAll {
            Remove-CaccaIISWebApp $testSiteName $appName
            Reset-IISServerManager -Confirm:$false
        }

        It 'Should configure existing pool' {
            # then
            $pool = Get-IISAppPool $appPoolName
            $pool.Enable32BitAppOnWin64 | Should -Be $false
            $pool.AutoStart | Should -Be $true
        }
    }

    Context '-AppPoolConfig, when pool does NOT exist' {
        BeforeAll {
            # given
            $appPoolName = 'NonSharedPool491'
            $appName = '/MyApp'

            # when
            New-CaccaIISWebApp $testSiteName $appName -AppPoolName $appPoolName -AppPoolConfig {
                $_.Enable32BitAppOnWin64 = $false
                $_.AutoStart = $false
            }

            Reset-IISServerManager -Confirm:$false
        }
    
        AfterAll {
            Remove-CaccaIISWebApp $testSiteName $appName
            Reset-IISServerManager -Confirm:$false
        }

        It 'Should configure new pool' {
            # then
            $pool = Get-IISAppPool $appPoolName
            $pool.Enable32BitAppOnWin64 | Should -Be $false
            $pool.AutoStart | Should -Be $false
        }
    }

    Context 'App already exists' {

        BeforeEach {
            # given
            $appPoolName = 'NonSharedPool67814'
            $appName = '/MyApp67814'
            New-CaccaIISWebApp $testSiteName $appName -AppPoolName $appPoolName -AppPoolConfig {
                $_.Enable32BitAppOnWin64 = $false
                $_.AutoStart = $false
            }
            Reset-IISServerManager -Confirm:$false
        }

        AfterEach {
            Remove-CaccaIISWebApp $testSiteName $appName
            Reset-IISServerManager -Confirm:$false
        }

        It 'Should throw' {
            # when
            { New-CaccaIISWebApp $testSiteName $appName -EA Stop } | Should Throw
        }

        It '-Force should replace existing app' {
            # when
            New-CaccaIISWebApp $testSiteName $appName -EA Stop -Force -AppPoolConfig {
                $_.ManagedRuntimeVersion = 'v1.1'
            }

            # then
            Reset-IISServerManager -Confirm:$false
            $app = (Get-IISSite $testSiteName).Applications[$appName]
            $app.ApplicationPoolName | Should -Be $testAppPoolName
            $pool = Get-IISAppPool $testAppPoolName
            $pool.ManagedRuntimeVersion | Should -Be 'v1.1'
        }
    }

    Context '-WhatIf' {
        BeforeAll {
            # given
            $appName = '/MyApp/Child9'
            $appPoolName = 'NonSharedPool26'

            # when
            New-CaccaIISWebApp $testSiteName $appName -AppPoolName $appPoolName -WhatIf
        }
    
        AfterAll {
            Reset-IISServerManager -Confirm:$false
        }

        It 'Should NOT have created child app' {
            # then
            $site = Get-IISSite $testSiteName
            $site.Applications[$appName] | Should -BeNullOrEmpty
        }

        It 'Should NOT have created file path' {
            # then
            $app = (Get-IISSite $testSiteName).Applications[$appName]
            $expectedPhysicalPath = "$sitePath$($appName.Replace('/', '\'))"
            $expectedPhysicalPath | Should -Not -Exist
        }

        It 'Should NOT have created new pool' {
            # then
            Get-IISAppPool $appPoolName | Should -BeNullOrEmpty
        }
    }
}