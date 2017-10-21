function divideByZero() {
    [CmdletBinding()]
    param()

    # also try replacing the divide by zero expression with the comment out code...
    # ... you will notice that this WILL produce a terminial error irrespective of caller's preferences
    # Get-LocalUser 'crap' -EA Stop

    1/(1-1)

    # this line WILL run unless the caller:
    # supplies -ErrorAction Stop
    # OR calls this function in a try/catch
    Write-Host 'still running inside divideByZero!'
}
Clear-Host

$ErrorActionPreference = 'Continue'

# the error thrown by function is NOT terminal:
# 1. 'still running...' is printed
# 2. 'mmm...' is printed
divideByZero; Write-Host 'mmm... should not reach here!'


# the error thrown by function is NOT terminal (note the -EA Stop):
# 1. 'mmm...' is printed
divideByZero -EA Stop; Write-Host 'mmm... should not reach here!'

# the error thrown by function IS terminal when wrapped in a try..catch
try {
    divideByZero; Write-Host 'mmm... should not reach here!'
}
catch {
    Write-Host "expected error: $_"
}