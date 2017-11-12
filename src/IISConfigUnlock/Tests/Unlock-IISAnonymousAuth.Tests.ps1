$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

Describe 'Unlock-IISAnonymousAuth' {
    $anonAuthSectionPath = 'system.webServer/security/authentication/anonymousAuthentication'

    AfterEach {
        # throw away local changes
        Reset-IISServerManager -Confirm:$false
    }

    It "Should unlock the anonymousAuthentication section in applicationHost.config" {
        # checking assumptions
        (Get-IISConfigSection $anonAuthSectionPath).OverrideMode | Should -Be 'Inherit'

        # when
        Unlock-CaccaIISAnonymousAuth -Commit:$false

        # then
        (Get-IISConfigSection $anonAuthSectionPath).OverrideMode | Should -Be 'Allow'
    }
    

    Context "Specific site" {
        $testSiteName = 'DeleteMeSite'
        $tempSitePath = "$Env:TEMP\$testSiteName"

        function CreateTestSite {
            New-Item $tempSitePath -ItemType Directory -EA Ignore
            New-IISSite $testSiteName $tempSitePath -BindingInformation "*:80:$($testSiteName)"
        }

        function Cleanup {
            Remove-IISSite $testSiteName -EA Ignore -Confirm:$false -WA SilentlyContinue
            Reset-IISServerManager -Confirm:$false
            Remove-Item $tempSitePath -Recurse -Confirm:$false -EA Ignore
        }

        BeforeEach {
            Cleanup
            CreateTestSite
        }
    
        AfterEach {
            Cleanup
        }

        It "Should lock section for site" {
            # checking assumptions
            (Get-IISConfigSection $anonAuthSectionPath -Location $testSiteName).OverrideMode | Should -Be 'Inherit'

            # when
            Unlock-CaccaIISAnonymousAuth -Location $testSiteName

            # then
            (Get-IISConfigSection $anonAuthSectionPath -Location $testSiteName).OverrideMode | Should -Be 'Allow'
        }
        
    }
}