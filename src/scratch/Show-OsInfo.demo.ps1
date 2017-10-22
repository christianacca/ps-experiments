function SaveShowOSInfoModule {
    $moduleName = 'Show-OSInfo'
    $moduleBasePath = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules"
    $modulePath = "$moduleBasePath\$moduleName"

    Remove-Item $modulePath -Force -Recurse -EA 'Ignore' -Confirm:$false
    New-Item -Path $modulePath -Force -ItemType Directory
    Copy-Item -Path .\src\Show-OsInfo\*.* -Destination $modulePath -Force
}

SaveShowOSInfoModule
Clear-Host

# Now run the comand
Import-Module Show-OSInfo -Force
Show-CaccaOSInfo -ComputerName localhost
