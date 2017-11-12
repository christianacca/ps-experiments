function Get-TempAspNetFilesPaths {
    Set-StrictMode -Version Latest
    
    $aspNetTempFolder = 'C:\Windows\Microsoft.NET\Framework*\v*\Temporary ASP.NET Files'
    Get-ChildItem $aspNetTempFolder | Select-Object -Exp FullName
}