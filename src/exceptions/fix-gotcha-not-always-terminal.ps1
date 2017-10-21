function Set-Something {
    [CmdletBinding()]
    param()
    process {
        $callerEA = $ErrorActionPreference
        try {
            # $ErrorActionPreference = 'Stop'
            # Get-LocalUser 'nope' -EA Stop
    
            1 / (1 - 1)
            Write-Host 'still running inside Set-Something!'
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}
Clear-Host

$ErrorActionPreference = 'Continue'

# the error thrown by function is NOT terminal to the script because that's our global preference
Set-Something; Write-Host 'script...still running (1)'

# our call specific preference overrides global preference
Set-Something -EA 'SilentlyContinue'; Write-Host 'script...still running (2)'

try {
    Set-Something -EA Stop; Write-Host 'script...still running (3)'
}
catch {
    Write-Host "expected error: $_"
}

# the error thrown by function IS terminal:
Set-Something -EA Stop; Write-Host 'script...still running (4)'