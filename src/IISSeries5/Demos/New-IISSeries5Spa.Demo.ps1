$modulePath = Resolve-Path "$PSScriptRoot\..\*\*.psd1"
$moduleName = Split-Path (Split-Path $modulePath) -Leaf

Get-Module $moduleName -All | Remove-Module
Import-Module $modulePath

$params = @{
    AppPath  = 'C:\Git\Series5\src\Ram.Series5.Spa'
    WinLoginAppPath  = 'C:\Git\Series5\src\Ram.Series5.WinLogin'
    HostName = 'local-series5'
    LocalDns = $true
}
New-RamIISSeries5Spa @params
