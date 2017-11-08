function CheckPathExists([string] $Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $true
    }

    if (-not(Test-Path $Path)) {
        throw "Path '$Path' not found"
    }
    $true
}