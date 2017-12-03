[CmdletBinding(DefaultParameterSetName = 'Path')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Bootstrap')]
    [switch] $Init,

    [Parameter(Mandatory, ParameterSetName = 'DevInstall')]
    [switch] $DevInstall,
    
    [Parameter(Mandatory, ParameterSetName = 'Path')]
    [ValidateNotNullOrEmpty()]
    [string] $Path,

    [Parameter(Mandatory, ParameterSetName = 'Scriptblock')]
    [scriptblock] $Script
)

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'


Write-Information "Starting"

. "$PSScriptRoot\bootstrap.ps1"

if ($Init) {
    return
}

$scriptFile = if (![string]::IsNullOrEmpty($Path)) {
    $Path
} elseif ($DevInstall) {
    'dev-install'
}

if (![string]::IsNullOrWhiteSpace($scriptFile)) {
    Write-Information '  Run Script'
    . "$PSScriptRoot\$scriptFile.ps1"
} else {
    Write-Information '  Run Script Block'
    & $Script
}
