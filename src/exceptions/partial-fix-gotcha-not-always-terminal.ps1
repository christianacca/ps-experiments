function divideByZero() {
    [CmdletBinding()]
    param()
    process {
        try {
            
            # also try replacing the divide by zero expression with the comment out code...
            # ... this will have identical behaviour to the divide by zero
            # Get-LocalUser 'crap' -EA Stop
                
            1 / (1 - 1)
                        
            # this line will NOT
            Write-Host 'still running inside divideByZero!'
        }
        catch {
            # throw
            # using `ThrowTerminatingError` has the benefit of hiding internal details of error
            # however, caller must now wrap its call to this function
            # in a try..catch in order to receive a terminiating exception
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
Clear-Host

$ErrorActionPreference = 'Continue'

# the error thrown by function is NOT terminal to the script
# but at least the called function consistently does NOT continue to print 'still running...'
divideByZero; Write-Host 'mmm... should not reach here!'


# the error thrown by function is NOT terminal:
# (-EA Stop is "ignored")
divideByZero -EA 'Stop'; Write-Host 'mmm... should not reach here!'

# the error thrown by function IS terminal
try {
    divideByZero; Write-Host 'mmm... should not reach here!'
}
catch {
    Write-Host "expected error: $_"
}