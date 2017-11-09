function CheckPathExists([string] $Path) {
    Set-StrictMode -Version Latest
    
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $true
    }

    if (-not(Test-Path $Path)) {
        throw "Path '$Path' not found"
    }
    $true
}