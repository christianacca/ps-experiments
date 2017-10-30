# $scripts = ".\src\Install-Utils\Install-Utils\*.ps1"
$scripts = "$PSScriptRoot\*.ps1"
Get-ChildItem $scripts | ForEach-Object { . "$_" }
