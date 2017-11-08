# $scripts = ".\src\Publish-Utils\Publish-Utils\*.ps1"
$scripts = "$PSScriptRoot\*.ps1"
Get-ChildItem $scripts | ForEach-Object { . "$_" }
