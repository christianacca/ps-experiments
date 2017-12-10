#Requires -RunAsAdministrator

. "$PSScriptRoot\EnsurePSDepend.ps1"
. "$PSScriptRoot\EnsureTestModulesNotInstalled.ps1"

Describe 'Import' {

    BeforeAll {
        EnsurePSDepend
    }

    Context 'Standalone module' {

        function CleanupStandaloneModule {
            # ensure module not already installed
            Get-Module _LibraryTest1 -All | Remove-Module -Force
            Uninstall-Module _LibraryTest1 -AllVersions -EA Ignore -Force
        }

        Context 'Import from PSModulePath' {

            BeforeAll {
                CleanupStandaloneModule

                # given...          
                $projectPath = "$TestDrive\$(Get-Random -Maximum 1000000)"
                
                $requirements = "@{ '_LibraryTest1' = '1.0.0.3' }"
                New-Item "$projectPath\requirements.psd1" -Value $requirements -Force

                Invoke-PSDepend $projectPath -Install -Force
            }

            AfterAll {
                CleanupStandaloneModule
            }
            

            It 'Should have imported exact version required only' {
                # when
                Invoke-PSDepend $projectPath -Force -Import

                # then
                $standaloneModule = @(Get-Module _LibraryTest1 -All)
                $standaloneModule.Count | Should -Be 1
                $standaloneModule.Version | Should -Be '1.0.0.3'
            }
        }
            
        Context 'Import from folder' {
            BeforeAll {
                CleanupStandaloneModule

                # given...                

                $projectPath = "$TestDrive\$(Get-Random -Maximum 1000000)"

                $requirements = "@{ 
                    PSDependOptions = @{ Target = '$projectPath\' } 
                    '_LibraryTest1' = '1.0.0.3' 
                }"
                New-Item "$projectPath\requirements.psd1" -Value $requirements -Force

                Invoke-PSDepend $projectPath -Install -Force
            }
            
            It 'Should have installed module to target path' {
                # when
                Invoke-PSDepend $projectPath -Force -Import
                
                # then
                $standaloneModule = @(Get-Module _LibraryTest1 -All)
                $standaloneModule.Count | Should -Be 1
                $standaloneModule.Version | Should -Be '1.0.0.3'
            }

            AfterAll {
                CleanupStandaloneModule
            }
        }
    }

    Context 'Module with dependency' {

        Context 'Import top level module from PSModulePath' {

            BeforeAll {
                EnsureTestModulesNotInstalled

                # given...  
                
                $projectPath = "$TestDrive\$(Get-Random -Maximum 1000000)"

                $requirements = "@{ DemoRequiringModule = '1.0.0' }"
                New-Item "$projectPath\requirements.psd1" -Value $requirements -Force

                Invoke-PSDepend $projectPath -Install -Force


                # when
                Invoke-PSDepend $projectPath -Import -Force
            }

            AfterAll {
                EnsureTestModulesNotInstalled
            }

            It 'Should have imported top level module' {
                @(Get-Module DemoRequiringModule -All).Count | Should -Be 1
            }
            
            It 'Should have imported dependent module' {
                @(Get-Module DemoRequiredModule -All).Count | Should -Be 1
            }
        }

        Context 'Import top level module from folder' {
            
            AfterAll {
                EnsureTestModulesNotInstalled
            }
            
            BeforeAll {
                EnsureTestModulesNotInstalled

                # given...  

                $projectPath = "$TestDrive\$(Get-Random -Maximum 1000000)"
            
                $requirements = "@{ 
                    PSDependOptions = @{ 
                        Target = '$projectPath\' 
                        AddToPath = `$true
                    }
                    DemoRequiringModule = '1.0.0'
                }"
                New-Item "$projectPath\requirements.psd1" -Value $requirements -Force
            
                Invoke-PSDepend $projectPath -Install -Force
                

                # when
                Invoke-PSDepend $projectPath -Import -Force
            }
            

            It 'Should have imported top level module' {
                # then
                @(Get-Module DemoRequiringModule -All).Count | Should -Be 1
            }
            
            It 'Should have imported dependent module' {
                # then
                @(Get-Module DemoRequiredModule -All).Count | Should -Be 1
            }
        }

        Context 'Import top level module AND dependency from folder' {
            
            AfterAll {
                EnsureTestModulesNotInstalled
            }

            BeforeAll {
                EnsureTestModulesNotInstalled

                # given...  

                $projectPath = "$TestDrive\$(Get-Random -Maximum 1000000)"
            
                $requirements = "@{ 
                    PSDependOptions = @{ 
                        Target = '$projectPath\' 
                        AddToPath = `$true
                    } 
                    DemoRequiredModule  = '1.0.0'
                    DemoRequiringModule = @{
                        Version = '1.0.0'
                        DependsOn = 'DemoRequiredModule'
                    }
                }"
                New-Item "$projectPath\requirements.psd1" -Value $requirements -Force
            
                Invoke-PSDepend $projectPath -Install -Force
                        
                # when
                Invoke-PSDepend $projectPath -Import -Force
            }

            It 'Should have imported top level module' {
                # then
                @(Get-Module DemoRequiringModule -All).Count | Should -Be 1
            }
            
            It 'Should have imported specific version of dependent module only' {
                # then
                $module = @(Get-Module DemoRequiredModule -All)
                $module.Count | Should -Be 1
                $module.Version | Should -Be '1.0.0'
            }
        }
    }
}

