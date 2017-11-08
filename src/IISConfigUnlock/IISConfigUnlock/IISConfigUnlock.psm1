# $scripts = ".\src\Unlock-IISConfig\Unlock-IISConfig\*.ps1"
$scripts = "$PSScriptRoot\*.ps1"
Get-ChildItem $scripts | ForEach-Object { . "$_" }
