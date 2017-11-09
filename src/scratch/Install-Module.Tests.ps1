$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testModuleName = '_LibraryTest1'
$currentVs = ''

Describe 'Install-Module' {

    BeforeAll {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        $currentVs = (Find-Module $testModuleName).Version
    }

    BeforeEach {
        Uninstall-Module $testModuleName -AllVersions -Force -EA Ignore
    }

    It 'Can install module' {

        # when
        Install-Module $testModuleName

        # then
        $installedModule = Get-InstalledModule $testModuleName -AllVersions
        $installedModule | Should -Not -Be $null
        $installedModule.Version | Should -Be $currentVs
    }

    It 'Can install specific version of module' {
        # when
        Install-Module $testModuleName -RequiredVersion '1.0.0.1'

        $installedModule = Get-InstalledModule $testModuleName -AllVersions
        $installedModule | Should -Not -Be $null
        $installedModule.Version | Should -Be '1.0.0.1'
    }

    It '-Force will install latest version of module, side-by-side with existing' {
        # given
        Install-Module $testModuleName -RequiredVersion '1.0.0.1'

        # when
        Install-Module $testModuleName -Force

        # then
        $installedModule = Get-InstalledModule $testModuleName -AllVersions
        ($installedModule | Measure-Object).Count | Should -Be 2
    }

    It 'Install without vs will do nothing without -Force when older version already installed' {
        # given
        Install-Module $testModuleName -RequiredVersion '1.0.0.1'

        # when
        # note: that PSRepo(s) will still be checked for newer vs therefore this is slow
        Install-Module $testModuleName -EA Stop

        # then
        $installedModule = Get-InstalledModule $testModuleName -AllVersions
        ($installedModule | Measure-Object).Count | Should -Be 1
        $installedModule.Version | Should -Be '1.0.0.1'
    }
    
    It '-Force is NOT required to install specific newer version of module side-by-side with older install' {
        # given
        Install-Module $testModuleName -RequiredVersion '1.0.0.1'

        # when
        Install-Module $testModuleName -RequiredVersion '1.0.0.3'

        # then
        $installedModule = Get-InstalledModule $testModuleName -AllVersions
        ($installedModule | Measure-Object).Count | Should -Be 2
    }

    It '-Force is NOT required to install specific older version of module side-by-side with newer install' {
        # given (latest vs installed)
        Install-Module $testModuleName

        # checking assumptions
        (Get-InstalledModule $testModuleName -AllVersions).Version | Should -Be $currentVs

        # when
        Install-Module $testModuleName -RequiredVersion '1.0.0.1' -EA Stop

        # then
        $installedModule = Get-InstalledModule $testModuleName -AllVersions
        ($installedModule | Measure-Object).Count | Should -Be 2
    }
}