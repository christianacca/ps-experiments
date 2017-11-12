$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$testSiteName = 'DeleteMeSite'
$tempAppPool = 'TestAppPool'

Describe 'Remove-IISAppPool' {

    AfterEach {
        Reset-IISServerManager -Confirm:$false
    }

    It 'Should throw if pool does not exist' {
        {Remove-CaccaIISAppPool 'DoesNotExist' -EA Stop} | Should Throw
    }

    Context 'Existing pool (not in use)' {
        BeforeEach {
            New-CaccaIISAppPool $tempAppPool -PassThru -Commit:$false
        }

        It 'Should delete pool' {
            # when
            Remove-CaccaIISAppPool $tempAppPool -Commit:$false

            # then
            Get-IISAppPool $tempAppPool -WA Ignore | Should -BeNullOrEmpty
        }
    }

    Context 'Existing pool in use by Web app' {
        
        function Cleanup {
            Reset-IISServerManager -Confirm:$false
            Start-IISCommitDelay
            $manager = Get-IISServerManager
            Remove-IISSite $testSiteName -EA Ignore -Confirm:$false -WA 'Ignore'
            $pool = $manager.ApplicationPools[$tempAppPool]
            if ($pool) {
                $manager.ApplicationPools.Remove($pool)
            }
            Stop-IISCommitDelay
            Reset-IISServerManager -Confirm:$false
        }

        BeforeEach {
            Cleanup
            New-CaccaIISWebsite $testSiteName $TestDrive -AppPoolName $tempAppPool
        }

        AfterEach {
            Cleanup
        }

        It 'Should throw' {
            {Remove-CaccaIISAppPool $tempAppPool -EA Stop} | Should Throw
            Get-IISAppPool $tempAppPool | Should -Not -BeNullOrEmpty
        }
    
        It '-Force should allow delete' {
            Remove-CaccaIISAppPool $tempAppPool -Force
            Get-IISAppPool $tempAppPool -WA Ignore | Should -BeNullOrEmpty
        }
    }
}