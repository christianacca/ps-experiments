function ValidateAclPaths {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [PsCustomObject[]] $Permissions,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ErrorMessage
    )
    Set-StrictMode -Version Latest

    $Permissions | Select-Object -Exp Path | 
        Where-Object { -not(Test-Path $_ ) } -OutVariable missingPaths | 
        ForEach-Object { Write-Warning "Path not found: '$_'" }
    if ($missingPaths) {
        throw $ErrorMessage
    }
}