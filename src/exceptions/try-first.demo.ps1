. .\src\scratch\try-first.ps1

$cmd1 = {
    Write-Verbose 'trying command 1'
    throw "command 1 not working"
}

$cmd2 = {
    Write-Verbose 'trying command 2'
    Write-Error 'command 2 not worked'
}

$cmd3 = {
    Write-Verbose 'trying command 3'
    Write-Output 'command 3 worked'
}

$cmd4 = {
    Write-Verbose 'trying command 4'
    Write-Output 'command 4 worked'
}
Clear-Host

$result = Try-First @($cmd1, $cmd2, $cmd3, $cmd4) -Verbose
Write-Host $result