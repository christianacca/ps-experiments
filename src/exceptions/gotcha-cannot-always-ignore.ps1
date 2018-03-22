function Get-ProcessWrapper {
    [CmdletBinding()]
    param()
    begin {
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    process {
        try {
            # note: the erorr from Get-SomethingById is always terminal even when we explicitly say to Ignore the error
            # this happens only when PS cannot bind the argument (eg '$processIds') to the function parameter (eg 'Id')
            # thinking more about this... behaviour IS expected:
            # -ErrorAction Ignore determines the behaviour of the function it is applied when it is EXECUTING
            # in this case, Get-SomethingById is NOT called because Powershell cannot bind the argument '$processIds'
            # because it is null
            # IMPORTANT: PS also cannot bind an empty array
            # IMPORTANT: if the 'Id' parameter was optional then PS WOULD call the function, at which point -ErrorAction
            #            value would be honored
            $processIds = $null
            # $processIds = @()
            $process = Get-SomethingById -Id $processIds -ErrorAction Ignore
            Write-Host 'Expected: still running inside Get-ProcessWrapper'
        }
        catch {
            Write-Error -ErrorRecord $_ -ErrorAction $callerEA
        }
    }
}

function Get-SomethingById 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int[]] $Id
    )
    begin {
        Write-Host 'Inside of Get-SomethingById:Begin'
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    process {
        try {
            throw "bad stuff"
            Write-Host 'Inside of Get-SomethingById'
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}

Clear-Host

Get-ProcessWrapper -EA 'Continue'
Write-Host 'Still running inside of script gotcha-cannot-always-ignore.ps1'