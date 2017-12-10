Describe 'Import-Module' {

    function Cleanup {
        Get-Module DemoRequiring2LevelModule -All -EA Ignore | Remove-Module -Force
        Get-Module DemoRequiringExactModule -All -EA Ignore | Remove-Module -Force
        Get-Module DemoRequiredModule -All -EA Ignore | Remove-Module -Force
        Get-InstalledModule DemoRequiring2LevelModule -AllVersions -EA Ignore | Uninstall-Module
        Get-InstalledModule DemoRequiringExactModule -AllVersions -EA Ignore | Uninstall-Module
        Get-InstalledModule DemoRequiredModule -AllVersions -EA Ignore | Uninstall-Module
    }

    Context 'Module with dependent RequiredModule' {
        
        Context 'Version installed newer than RequiredModule' {
            
            BeforeAll {
                Cleanup

                # given
                Get-Module DemoRequiringExactModule -All | Remove-Module -Force
                Get-Module DemoRequiredModule -All | Remove-Module -Force
                Install-Module DemoRequiredModule -RequiredVersion '1.0.0' -EA Stop
                Install-Module DemoRequiredModule -RequiredVersion '1.1.0' -EA Stop
                Install-Module DemoRequiringExactModule -RequiredVersion '1.0.0' -EA Stop
            }

            AfterAll {
                Cleanup
            }
            
            It 'should import the version of dependent module as specified by manifest' {
                # when
                Import-Module DemoRequiringExactModule -RequiredVersion '1.0.0'

                # then
                $requiredModule = @(Get-Module DemoRequiredModule)
                $requiredModule.Count | Should -Be 1
                $requiredModule.Version | Should -Be '1.0.0'
            }
        }
    }

    Context 'Module with 2 levels of dependent RequiredModule' {

        # DemoRequiring2LevelModule 
        # |
        # --(1.0.0)--> DemoRequiringExactModule
        # |            |
        # |             --(1.0.0)--> DemoRequiredModule
        # |                             ^
        # |                             |
        # ----------------(1.0.0-1.1.0)--
        
        Context 'Multiple versions of dependent module installed' {
            
            BeforeAll {
                Cleanup

                # given
                Install-Module DemoRequiredModule -RequiredVersion '1.0.0' -EA Stop
                Install-Module DemoRequiredModule -RequiredVersion '1.1.0' -EA Stop
                Install-Module DemoRequiringExactModule -RequiredVersion '1.0.0' -EA Stop
                Install-Module DemoRequiring2LevelModule -RequiredVersion '1.0.1' -EA Stop
            }

            AfterAll {
                Cleanup
            }

            AfterEach {
                Get-Module DemoRequiring2LevelModule -All -EA Ignore | Remove-Module -Force
                Get-Module DemoRequiringExactModule -All -EA Ignore | Remove-Module -Force
                Get-Module DemoRequiredModule -All -EA Ignore | Remove-Module -Force
            }
            
            It 'can result in the import of multiple versions of the same module' {

                # when
                Import-Module DemoRequiring2LevelModule -RequiredVersion '1.0.1'

                # then
                $requiredModule = @(Get-Module DemoRequiredModule)
                $requiredModule.Count | Should -Be 2
                $requiredModule.Version | Should -Be @('1.0.0', '1.1.0')
            }

            It 'Version statisfying dependency range already imported will be used' {
                # given
                Import-Module DemoRequiredModule -RequiredVersion '1.0.0'

                # when
                Import-Module DemoRequiring2LevelModule -RequiredVersion '1.0.1'

                # then
                $requiredModule = @(Get-Module DemoRequiredModule)
                $requiredModule.Count | Should -Be 1
                $requiredModule.Version | Should -Be '1.0.0'
            }
        }

        Context 'One satisfying version of dependent module installed' {
            
            BeforeAll {
                Cleanup

                # given
                Install-Module DemoRequiredModule -RequiredVersion '1.0.0' -EA Stop
                Install-Module DemoRequiringExactModule -RequiredVersion '1.0.0' -EA Stop
                Install-Module DemoRequiring2LevelModule -RequiredVersion '1.0.1' -EA Stop
            }

            AfterAll {
                Cleanup
            }
            
            It 'Should import the one version of the module available' {

                # when
                Import-Module DemoRequiring2LevelModule -RequiredVersion '1.0.1'

                # then
                $requiredModule = @(Get-Module DemoRequiredModule)
                $requiredModule.Count | Should -Be 1
                $requiredModule.Version | Should -Be '1.0.0'
            }
        }
    }

}