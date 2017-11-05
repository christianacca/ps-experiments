function Get-Stuff {
    param(
        [int] $IntValue = 10,
        [string[]] $ArrayValue = @('Hello', 'World'),
        [ValidateNotNull()]
        [string[]] $VaidatedArrayValue = @(),
        [string] $StringValue = '2'
    )

    $Value
    $ArrayValue
    $VaidatedArrayValue
    $StringValue

    if ($VaidatedArrayValue -eq $null) {
        'VaidatedArrayValue = $null'
    }
}

Get-Stuff -IntValue $null -ArrayValue $null -StringValue $null