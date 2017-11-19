function Set-Something {
    [CmdletBinding()]
    param()
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        Write-Verbose "Caller ErrorActionPreference: $callerEA"
    }
    process {
        try {
            # Get-LocalUser 'nope' -EA Stop
    
            1 / (1 - 1)
            Write-Host 'still running inside Set-Something!'
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}

function Set-SomethingElse {
    [CmdletBinding()]
    param ()
    
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {
            Set-Something
            Write-Host 'Set-SomethingElse... still running'
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

Set-SomethingElse -Verbose; Write-Host 'script...still running (4)'

# the error thrown by function IS terminal:
Set-Something -EA Stop; Write-Host 'script...still running (5)'