function UninstallModules {
    SafeUninstallModule DemoScopingModule1
    SafeUninstallModule DemoScopingModule2
}

function RemoveModules {
    Get-Module DemoScopingModule1 | Remove-Module -Force
    Get-Module DemoScopingModule2 | Remove-Module -Force
}

function InstallModules {
    InstallModuleIfMissing DemoScopingModule1
    InstallModuleIfMissing DemoScopingModule2
}


function SafeUninstallModule {
    param([string] $Name)
    Get-Module $Name | Remove-Module -Force
    Uninstall-Module $Name -AllVersions -Force -EA Ignore
}

function InstallModuleIfMissing {
    param([string] $Name)
    Get-Module $Name | Remove-Module -Force
    if (-not(Get-InstalledModule $Name -EA Ignore)) {
        Install-Module $Name -Repository LocalRepo -Scope CurrentUser
    }
}

Describe 'Module scoping demo' {

    BeforeAll {
        InstallModules
    }

    AfterAll {
        UninstallModules
    }

    Context 'DemoScopingModule1 imported first' {
        BeforeAll {
            # when
            Import-Module DemoScopingModule1
            Import-Module DemoScopingModule2
        }

        AfterAll {
            RemoveModules
        }

        It "DemoScopingModule1 should call own private 'Get-ValueImpl' function" {
            Get-ValueDemo1 | Should -Be 'Hello'
        }

        It "DemoScopingModule2 should call own private 'Get-ValueImpl' function" {
            Get-ValueDemo2 | Should -Be 'World'
        }
    }

    Context 'DemoScopingModule2 imported first' {
        BeforeAll {
            # when
            Import-Module DemoScopingModule2
            Import-Module DemoScopingModule1
        }

        AfterAll {
            RemoveModules
        }

        It "DemoScopingModule1 should call own private 'Get-ValueImpl' function" {
            Get-ValueDemo1 | Should -Be 'Hello'
        }

        It "DemoScopingModule2 should call own private 'Get-ValueImpl' function" {
            Get-ValueDemo2 | Should -Be 'World'
        }
    }
}