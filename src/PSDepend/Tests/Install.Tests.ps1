#Requires -RunAsAdministrator

. "$PSScriptRoot\EnsurePSDepend.ps1"
. "$PSScriptRoot\EnsureTestModulesNotInstalled.ps1"

Describe 'Install' {

    BeforeAll {
        EnsurePSDepend
    }

    Context 'Standalone module' {

        Context 'Install into PSModulePath' {

            BeforeAll {
                # given...          
                
                $projectPath = "$TestDrive\$(Get-Random -Maximum 1000000)"

                # ensure module not already installed
                Get-Module _LibraryTest1 -All | Remove-Module -Force
                Uninstall-Module _LibraryTest1 -AllVersions -EA SilentlyContinue -Force

                # define requirements
                $requirements = "@{ '_LibraryTest1' = '1.0.0.3' }"
                New-Item "$projectPath\requirements.psd1" -Value $requirements -Force

            
                # when
                Invoke-PSDepend $projectPath -Force

                $standaloneModule = Get-InstalledModule _LibraryTest1
            }
            
            It 'Should have installed module to desired location' {
                # then
                $moduleRootPath = Split-Path ($standaloneModule.InstalledLocation)
                $moduleRootPath | Should -Be "C:\Program Files\WindowsPowerShell\Modules\_LibraryTest1"
            }

            It 'Should have installed exact version required' {
                $standaloneModule.Version | Should -Be '1.0.0.3'
            }
        }
            
        Context 'Install into folder' {
            BeforeAll {
                # given...                

                $projectPath = "$TestDrive\$(Get-Random -Maximum 1000000)"

                # define requirements
                $requirements = "@{ 
                    PSDependOptions = @{ Target = '$projectPath\' } 
                    '_LibraryTest1' = '1.0.0.3' 
                }"
                New-Item "$projectPath\requirements.psd1" -Value $requirements -Force

            
                # when
                Invoke-PSDepend $projectPath -Force
            }
            
            It 'Should have installed module to target path' {
                # then
                "$projectPath\_LibraryTest1" | Should -Exist
            }
        }
    }

    Context 'Module with dependency' {

        Context 'Install top level module into PSModulePath' {

            BeforeAll {
                # given...  
                
                EnsureTestModulesNotInstalled
                $projectPath = "$TestDrive\$(Get-Random -Maximum 1000000)"

                # define requirements
                $requirements = "@{ DemoRequiringModule = '1.0.0' }"
                New-Item "$projectPath\requirements.psd1" -Value $requirements -Force

            
                # when
                Invoke-PSDepend $projectPath -Force
            }

            AfterAll {
                EnsureTestModulesNotInstalled
            }

            It 'Should have installed top level module' {
                Get-InstalledModule DemoRequiringModule | Should -Not -BeNullOrEmpty
            }
            
            It 'Should have installed dependent module' {
                @(Get-InstalledModule DemoRequiringModule).Count | Should -Be 1
            }
        }

        Context 'Install top level module into folder' {
            
            BeforeAll {
                # given...  

                $projectPath = "$TestDrive\$(Get-Random -Maximum 1000000)"
            
                # define requirements
                $requirements = "@{ 
                    PSDependOptions = @{ Target = '$projectPath\' } 
                    DemoRequiringModule = '1.0.0'
                }"
                New-Item "$projectPath\requirements.psd1" -Value $requirements -Force
            
                        
                # when
                Invoke-PSDepend $projectPath -Force
            }
            

            It 'Should have installed top level module into target path' {
                # then
                "$projectPath\DemoRequiringModule" | Should -Exist
            }
                        
            It 'Should have installed dependent module into target path' {
                "$projectPath\DemoRequiredModule" | Should -Exist
            }
        }

        Context 'Install top level module AND dependency into folder' {
            BeforeAll {
                # given...  

                $projectPath = "$TestDrive\$(Get-Random -Maximum 1000000)"
            
                # define requirements
                $requirements = "@{ 
                    PSDependOptions = @{ Target = '$projectPath\' } 
                    DemoRequiredModule  = '1.0.0'
                    DemoRequiringModule = '1.0.0'
                }"
                New-Item "$projectPath\requirements.psd1" -Value $requirements -Force
            
                        
                # when
                Invoke-PSDepend $projectPath -Force
            }

            It 'Should have installed specific version of dependent module into target path' {
                # then...
                "$projectPath\DemoRequiredModule\1.0.0" | Should -Exist
            }
                        
            It 'Should NOT have installed latest version of dependent module into target path' -Skip {
                # then
                # this fails - PS has *also* installed the lastest vs of DemoRequiredModule module
                $latestVs = (Find-Module DemoRequiredModule).Version
                "$projectPath\DemoRequiredModule\$latestVs" | Should -Not -Exist
            }
        }
    }
}

