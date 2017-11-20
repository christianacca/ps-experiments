Describe "Compare-Object" {
    It 'Should throw' {
        { throw "crap"} | Should Throw
    }

    It "Exact same object" {
        $actual = [PsCustomObject] @{
            File = 'C:\Scrap'
            Permission = 'R'
        }
        $other = $actual
        $actual | Compare-Object $other -Property File,Permission | Should -BeNullOrEmpty
    }

    It "Equivalent object" {
        $actual = [PsCustomObject] @{
            File = 'C:\Scrap'
            Permission = 'R'
        }
        $other = [PsCustomObject] @{
            File = 'C:\Scrap'
            Permission = 'R'
        }
        $actual | Compare-Object $other -Property File,Permission | Should -BeNullOrEmpty
    }

    It "Different property value" {
        $actual = [PsCustomObject] @{
            File = 'C:\Scrap'
            Permission = 'R'
        }
        $other = [PsCustomObject] @{
            File = 'C:\Scrap'
            Permission = 'RX'
        }
        $results = $actual | Compare-Object $other -Property ($other.PsObject.Properties.Name)
        $results | % { Write-Host $_}
        $results | Should -Not -BeNullOrEmpty
    }

    It "Different property value - nice output" -Skip {
        $actual = [PsCustomObject] @{
            File = 'C:\Scrap'
            Permission = 'R'
        }
        $other = [PsCustomObject] @{
            File = 'C:\Scrap'
            Permission = 'RX'
        }

        Compare-Object $actual.File $other.File | select -Exp InputObject | Should -Be $null
        Compare-Object $actual.Permission $other.Permission | select -Exp InputObject | Should -Be $null
    }
}