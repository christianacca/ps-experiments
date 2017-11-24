$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath


Describe 'Remove-IISSiteHostsFileEntry' {

    Context 'One Website, 1 hostname' {

        BeforeAll {
            # given
            Mock Remove-TecBoxHostnames {} -Verifiable -ParameterFilter {$Hostnames -eq 'myhostname'} `
                -ModuleName $moduleName
        }

        It 'Should remove' {
            
            $entry = [PsCustomObject]@{
                Hostname  = 'myhostname'
                IpAddress = '127.0.0.1'
                SiteName  = 'DeleteMeSite'
                IsShared  = $false
            }

            # when
            $entry | Remove-CaccaIISSiteHostsFileEntry
            
            # then
            Assert-VerifiableMocks
        }
    }

    Context 'One Website, 2 hostname' {

        BeforeEach {
            # given
            Mock Remove-TecBoxHostnames {} -Verifiable -ParameterFilter {$Hostnames -eq @('myhostname', 'othername')} `
                -ModuleName $moduleName

            $entry1 = [PsCustomObject]@{
                Hostname  = 'myhostname'
                IpAddress = '127.0.0.1'
                SiteName  = 'DeleteMeSite'
                IsShared  = $false
            }
            $entry2 = [PsCustomObject]@{
                Hostname  = 'othername'
                IpAddress = '127.0.0.1'
                SiteName  = 'DeleteMeSite'
                IsShared  = $false
            }
        }
        
        It 'Should remove, when entries supplied as an array' {
            
            # when
            Remove-CaccaIISSiteHostsFileEntry $entry1, $entry2
                        
            # then
            Assert-VerifiableMocks
        }

        It 'Should remove, when entries supplied by pipeline' {
            
            # when
            @($entry1, $entry2) | Remove-CaccaIISSiteHostsFileEntry
                        
            # then
            Assert-VerifiableMocks
        }
    }

    Context 'One entry shared' {
        
        Context 'No -Force' {
            BeforeAll {
                # given
                Mock Remove-TecBoxHostnames {} -Verifiable `
                    -ModuleName $moduleName
            }
    
            It 'Should throw' {
                
                $entry = [PsCustomObject]@{
                    Hostname  = 'myhostname'
                    IpAddress = '127.0.0.1'
                    SiteName  = 'DeleteMeSite'
                    IsShared  = $true
                }
    
                # when
                {$entry | Remove-CaccaIISSiteHostsFileEntry -EA Stop} | Should Throw
                
                # then
                Assert-MockCalled Remove-TecBoxHostnames -Times 0 -ParameterFilter {$Hostnames -eq 'myhostname'} `
                    -ModuleName $moduleName
            }
        }

        Context '-Force' {
            BeforeAll {
                # given
                Mock Remove-TecBoxHostnames {} -Verifiable -ParameterFilter {$Hostnames -eq 'myhostname'} `
                    -ModuleName $moduleName
            }
    
            It 'Should remove entry' {
                
                $entry = [PsCustomObject]@{
                    Hostname  = 'myhostname'
                    IpAddress = '127.0.0.1'
                    SiteName  = 'DeleteMeSite'
                    IsShared  = $true
                }
    
                # when
                & {$entry | Remove-CaccaIISSiteHostsFileEntry -Force -EA Stop; $true} | Should -Be $true
                
                # then
                Assert-VerifiableMocks
            }
        }
    }
}