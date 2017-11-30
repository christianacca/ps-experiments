Describe 'TestDrive examples' {
    BeforeAll {
        Write-Host "BeforeAll: $TestDrive"
    }

    BeforeEach {
        Write-Host "BeforeEach: $TestDrive"
    }

    It 'It block' {
        Write-Host "It: $TestDrive"
        $true | Should -Be $true
    }

    Context 'Context1' {
        BeforeAll {
            Write-Host "Context1.BeforeAll: $TestDrive"
        }
            
        BeforeEach {
            Write-Host "Context1.BeforeEach: $TestDrive"
        }
            
        It 'Context1: It block' {
            Write-Host "Context1.It: $TestDrive"
            $true | Should -Be $true
        }

        Context 'Context1_1' {
            BeforeAll {
                Write-Host "Context1_1.BeforeAll: $TestDrive"
            }
                
            BeforeEach {
                Write-Host "Context1_1.BeforeEach: $TestDrive"
            }
                
            It 'Context1: It block' {
                Write-Host "Context1_1.It: $TestDrive"
                $true | Should -Be $true
            }
        }
    }

    Context 'Context2' {
        BeforeAll {
            Write-Host "Context2.BeforeAll: $TestDrive"
        }
            
        BeforeEach {
            Write-Host "Context2.BeforeEach: $TestDrive"
        }
            
        It 'Context1: It block' {
            Write-Host "Context2.It: $TestDrive"
            $true | Should -Be $true
        }
    }
}