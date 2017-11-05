. .\src\exceptions\MyException.ps1
. .\src\exceptions\throwing-function.ps1

try {
    Get-Stuff '?' -EA Stop
}
catch [MyException] {
    Write-Host 'Logic to handle MyException'
}

$obj = try {
    Get-Stuff '?' -EA Stop
}
catch [MyException] {
    [PSCustomObject] @{
        Name = 'fallback'
    }
}
$obj