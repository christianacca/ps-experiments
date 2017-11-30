. "$PSScriptRoot\EnsurePSDepend.ps1"


Describe 'Remove-ExcessInstalledModules' {
    BeforeAll {
        EnsurePSDepend

        # given...  
    
        $projectPath = "$TestDrive\$(Get-Random -Maximum 10000)"

        # define requirements
        $requirements = "@{ 
            PSDependOptions = @{ Target = '$projectPath\' } 
            DemoRequiredModule  = '1.0.0'
            DemoRequiringModule = @{
                Version = '1.0.0'
                DependsOn = 'DemoRequiredModule'
            }
            PostInstallFix = @{
                DependencyType = 'Command'
                Source = 'Remove-ExcessInstalledModules `$DependencyPath'
            }
        }"
        New-Item "$projectPath\requirements.psd1" -Value $requirements -Force
    
                
        # when
        Invoke-PSDepend $projectPath -Confirm:$false
        Remove-ExcessInstalledModules "$projectPath\requirements.psd1"
    }

    AfterAll {
        Get-Module DemoRequiringModule -All | Remove-Module -Force
        Get-Module DemoRequiredModule -All | Remove-Module -Force
    }
                
    It 'Should remove latest version of dependent module from target path' {
        # then
        $latestVs = (Find-Module DemoRequiredModule).Version
        "$projectPath\DemoRequiredModule\$latestVs" | Should -Not -Exist
    }

    It 'Should keep version of modules in requirements spec' {
        # then...
        "$projectPath\DemoRequiredModule\1.0.0" | Should -Exist
        "$projectPath\DemoRequiringModule\1.0.0" | Should -Exist
    }

    It 'Should be able to import remaining installed modules' {
        # when
        Invoke-PSDepend "$projectPath\requirements.psd1" -Import -Force
        
        # then
        $depedency = @(Get-Module DemoRequiredModule -All)
        $depedency.Count | Should -Be 1
        $depedency.Version | Should -Be '1.0.0'

        $requiringModule = @(Get-Module DemoRequiringModule -All)
        $depedency.Count | Should -Be 1
        $depedency.Version | Should -Be '1.0.0'
    }
}