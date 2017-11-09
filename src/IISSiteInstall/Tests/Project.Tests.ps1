#Requires -Modules InstallUtils

$projectRoot = Resolve-Path "$PSScriptRoot\.."
$modulePath = Resolve-Path "$projectRoot\*\*.psd1"
$moduleRoot = Split-Path $modulePath
$moduleName = Split-Path $moduleRoot -Leaf

Describe "General project validation: $moduleName" {

    $scripts = Get-ChildItem $projectRoot -Include *.ps1,*.psm1,*.psd1 -Recurse

    # TestCases are splatted to the script so we need hashtables
    $testCase = $scripts | Foreach-Object{@{file=$_}}         
    It "Script <file> should be valid powershell" -TestCases $testCase {
        param($file)

        $file.fullname | Should Exist

        $contents = Get-Content -Path $file.fullname -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
        $errors.Count | Should Be 0
    }

    It "Module '$moduleName' can import cleanly" {
        {Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force } | Should Not Throw
    }

    It 'Module auto-imports dependencies' {
        # given
        # dependencies already installed
        Get-Module IISSecurity -All | Remove-Module
        Get-Module IISConfigUnlock -All | Remove-Module
        Install-Module IISSecurity -RequiredVersion '0.1.0'
        Install-Module IISConfigUnlock -RequiredVersion '0.1.0'
        # Module not already loaded into memory
        Get-Module $moduleName -All | Remove-Module

        # when
        Import-Module $modulePath

        # then
        Get-Module IISSecurity | Should -Not -Be $null
        Get-Module IISConfigUnlock | Should  -Not -Be $null
    }
}