$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

. "$PSScriptRoot\Compare-ObjectProperties.ps1"

Describe "Get-IISSiteDesiredAcl" {
    It "Can be import" {
        Get-Module $moduleName | Should -Not -BeNullOrEmpty
    }

    It "site only" {
        $permissions = Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -EA Stop

        $expected = 0..4 | % { '(OI)(CI)R' }
        $permissions.Count | Should -Be 5
        Compare-Object $permissions.Permission $expected | select -Exp InputObject | Should -Be $null
    }
    
    It "site only -SkipTempAspNetFiles" {
        $permissions = Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -SkipTempAspNetFiles

        $expected = [PsCustomObject] @{
            Path       = 'C:\inetpub\wwwroot\'
            Permission = '(OI)(CI)R'
        }
        ($permissions | Measure-Object).Count | Should -Be 1
        Compare-ObjectProperties ($permissions | select Path, Permission) $expected | Should -Be $null
    }
        
    It "site only -SiteShellOnly" {
        $permissions = Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -SiteShellOnly -SkipTempAspNetFiles

        $expected = [PsCustomObject] @{
            Path       = 'C:\inetpub\wwwroot\'
            Permission = '(OI)(NP)R'
        }
        ($permissions | Measure-Object).Count | Should -Be 1
        Compare-ObjectProperties ($permissions | select Path, Permission) $expected | Should -Be $null
    }

    It "SitePath missing and -SiteShellOnly, should throw" {
        {Get-CaccaIISSiteDesiredAcl -AppPath 'C:\inetpub\wwwroot' -SiteShellOnly  -EA Stop} | Should Throw
    }

    It "SitePath and AppPath  missing, should throw" {
        {Get-CaccaIISSiteDesiredAcl -EA Stop} | Should Throw
    }

    It "site only, one -ModifyPaths" {
        $permissions = Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -ModifyPaths 'App_Data' -SkipTempAspNetFiles
        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\'
                Permission = '(OI)(CI)R'
            },
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\App_Data'
                Permission = '(OI)(CI)M'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 2
        Compare-ObjectProperties ($permissions[0] | select Path, Permission) $expected[0] | Should -Be $null
        Compare-ObjectProperties ($permissions[1] | select Path, Permission) $expected[1] | Should -Be $null
    }
    
    It "site only, multiple -ModifyPaths" {
        $permissions = Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -ModifyPaths 'App_Data', 'logs' -SkipTempAspNetFiles

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\'
                Permission = '(OI)(CI)R'
            },
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\App_Data'
                Permission = '(OI)(CI)M'
            },
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\logs'
                Permission = '(OI)(CI)M'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 3
        Compare-ObjectProperties ($permissions[0] | select Path, Permission) $expected[0] | Should -Be $null
        Compare-ObjectProperties ($permissions[1] | select Path, Permission) $expected[1] | Should -Be $null
        Compare-ObjectProperties ($permissions[2] | select Path, Permission) $expected[2] | Should -Be $null
    }

    It "site only, one -ModifyPaths, -SiteShellOnly" {
        $params = @{
            SitePath            = 'C:\inetpub\wwwroot'
            ModifyPaths         = 'App_Data'
            SiteShellOnly       = $true
            SkipTempAspNetFiles = $true
        }
        $permissions = Get-CaccaIISSiteDesiredAcl @params

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\'
                Permission = '(OI)(NP)R'
            },
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\App_Data'
                Permission = '(OI)(CI)M'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 2
        Compare-ObjectProperties ($permissions[0] | select Path, Permission) $expected[0] | Should -Be $null
        Compare-ObjectProperties ($permissions[1] | select Path, Permission) $expected[1] | Should -Be $null
    }
    
    It "site only, same path as -ModifyPaths, -SiteShellOnly" {
        $params = @{
            SitePath            = 'C:\inetpub\wwwroot'
            ModifyPaths         = 'C:\inetpub\wwwroot'
            SiteShellOnly       = $true
            SkipTempAspNetFiles = $true
        }
        $permissions = Get-CaccaIISSiteDesiredAcl @params

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot' # <- note the missing trailing backslash (acceptable?)
                Permission = '(OI)(CI)M'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 1
        Compare-ObjectProperties ($permissions | select Path, Permission) $expected | Should -Be $null
    }

    It "site and relative child app" {
        $permissions = Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'MyWebApp1' -SkipTempAspNetFiles

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\'
                Permission = '(OI)(NP)R'
            },
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\MyWebApp1\'
                Permission = '(OI)(CI)R'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 2
        Compare-ObjectProperties ($permissions[0] | select Path, Permission) $expected[0] | Should -Be $null
        Compare-ObjectProperties ($permissions[1] | select Path, Permission) $expected[1] | Should -Be $null
    }

    It "site and absolute child app, outside of site root" {
        $permissions = Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'C:\inetpub\myapp' -SkipTempAspNetFiles

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\'
                Permission = '(OI)(NP)R'
            },
            [PsCustomObject] @{
                Path       = 'C:\inetpub\myapp\'
                Permission = '(OI)(CI)R'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 2
        Compare-ObjectProperties ($permissions[0] | select Path, Permission) $expected[0] | Should -Be $null
        Compare-ObjectProperties ($permissions[1] | select Path, Permission) $expected[1] | Should -Be $null
    }

    It "site and absolute child app" {
        $params = @{
            SitePath            = 'C:\inetpub\wwwroot'
            AppPath             = 'C:\inetpub\wwwroot\MyWebApp1'
            SkipTempAspNetFiles = $true
        }
        $permissions = Get-CaccaIISSiteDesiredAcl @params

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\'
                Permission = '(OI)(NP)R'
            },
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\MyWebApp1\'
                Permission = '(OI)(CI)R'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 2
        Compare-ObjectProperties ($permissions[0] | select Path, Permission) $expected[0] | Should -Be $null
        Compare-ObjectProperties ($permissions[1] | select Path, Permission) $expected[1] | Should -Be $null
    }

    It 'site and relave relative child app, -SiteShellOnly:$false' {
        $params = @{
            SitePath            = 'C:\inetpub\wwwroot'
            AppPath             = 'MyWebApp1'
            SiteShellOnly       = $false
            SkipTempAspNetFiles = $true
        }
        $permissions = Get-CaccaIISSiteDesiredAcl @params

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\'
                Permission = '(OI)(CI)R'
            },
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\MyWebApp1\'
                Permission = '(OI)(CI)R'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 2
        Compare-ObjectProperties ($permissions[0] | select Path, Permission) $expected[0] | Should -Be $null
        Compare-ObjectProperties ($permissions[1] | select Path, Permission) $expected[1] | Should -Be $null
    }

    It 'site and absolute child app, -SiteShellOnly:$false' {
        $params = @{
            SitePath            = 'C:\inetpub\wwwroot'
            AppPath             = 'C:\Apps\MyWebApp1'
            SiteShellOnly       = $false
            SkipTempAspNetFiles = $true
        }
        $permissions = Get-CaccaIISSiteDesiredAcl @params

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\'
                Permission = '(OI)(CI)R'
            },
            [PsCustomObject] @{
                Path       = 'C:\Apps\MyWebApp1\'
                Permission = '(OI)(CI)R'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 2
        Compare-ObjectProperties ($permissions[0] | select Path, Permission) $expected[0] | Should -Be $null
        Compare-ObjectProperties ($permissions[1] | select Path, Permission) $expected[1] | Should -Be $null
    }

    It "site and child app has same path" {
        $permissions = Get-CaccaIISSiteDesiredAcl -SitePath 'C:\inetpub\wwwroot' -AppPath 'C:\inetpub\wwwroot' -SkipTempAspNetFiles

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\'
                Permission = '(OI)(CI)R'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 1
        Compare-ObjectProperties ($permissions | select Path, Permission) $expected | Should -Be $null
    }

    It "site and child app has same path, -SiteShellOnly" {
        $params = @{
            SitePath            = 'C:\inetpub\wwwroot'
            AppPath             = 'C:\inetpub\wwwroot'
            SiteShellOnly       = $true
            SkipTempAspNetFiles = $true
        }
        $permissions = Get-CaccaIISSiteDesiredAcl @params

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\'
                Permission = '(OI)(NP)R'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 1
        Compare-ObjectProperties ($permissions | select Path, Permission) $expected | Should -Be $null
    }

    It "site and child app has same path, one -ModifyPaths" {
        $params = @{
            SitePath            = 'C:\inetpub\wwwroot'
            AppPath             = 'C:\inetpub\wwwroot'
            ModifyPaths         = 'App_Data'
            SkipTempAspNetFiles = $true
        }
        $permissions = Get-CaccaIISSiteDesiredAcl @params

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\'
                Permission = '(OI)(CI)R'
            },
            [PsCustomObject] @{
                Path       = 'C:\inetpub\wwwroot\App_Data'
                Permission = '(OI)(CI)M'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 2
        Compare-ObjectProperties ($permissions[0] | select Path, Permission) $expected[0] | Should -Be $null
        Compare-ObjectProperties ($permissions[1] | select Path, Permission) $expected[1] | Should -Be $null
    }

    It "child app only" {
        $permissions = Get-CaccaIISSiteDesiredAcl -AppPath 'C:\Apps\MyWebApp1' -SkipTempAspNetFiles

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\Apps\MyWebApp1\'
                Permission = '(OI)(CI)R'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 1
        Compare-ObjectProperties ($permissions | select Path, Permission) $expected | Should -Be $null
    }

    It "child app only, one relative -ModifyPaths" {
        $permissions = Get-CaccaIISSiteDesiredAcl -AppPath 'C:\Apps\MyWebApp1' -ModifyPaths 'App_Data' -SkipTempAspNetFiles

        $expected = @(
            [PsCustomObject] @{
                Path       = 'C:\Apps\MyWebApp1\'
                Permission = '(OI)(CI)R'
            },
            [PsCustomObject] @{
                Path       = 'C:\Apps\MyWebApp1\App_Data'
                Permission = '(OI)(CI)M'
            }
        )
        ($permissions | Measure-Object).Count | Should -Be 2
        Compare-ObjectProperties ($permissions[0] | select Path, Permission) $expected[0] | Should -Be $null
        Compare-ObjectProperties ($permissions[1] | select Path, Permission) $expected[1] | Should -Be $null
    }


}