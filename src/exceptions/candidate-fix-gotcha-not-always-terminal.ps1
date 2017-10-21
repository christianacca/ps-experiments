function Set-Something {
    [CmdletBinding()]
    param()
    process {
        try {
            
            Get-LocalUser 'nope' -EA Stop                        
            Write-Host 'still running inside divideByZero!'
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
Clear-Host

$ErrorActionPreference = 'Continue'
# the error thrown by function is NOT terminal to the script
# but at least the called function consistently does NOT continue to print 'still running...'
Set-Something -EA 'Stop'; Write-Host 'mmm... should not reach here!'

# the error thrown by function IS terminal
try {
    Set-Something; Write-Host 'mmm... should not reach here!'
}
catch {
    Write-Host "expected error: $_"
}