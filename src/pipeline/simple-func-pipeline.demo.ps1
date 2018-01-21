function Echo-Value([int] $Number) {
    $Number
}

function Square-Value([int] $Number) {
    $Number*$Number
}

@(1,2,3) | % { Square-Value -Number $_ } | % { Echo-Value -Number $_ }