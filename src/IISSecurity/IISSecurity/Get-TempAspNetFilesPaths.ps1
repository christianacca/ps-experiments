function Get-TempAspNetFilesPaths {
    [CmdletBinding()]
    param()
    Set-StrictMode -Version Latest
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    $aspNetTempFolder = 'C:\Windows\Microsoft.NET\Framework*\v*\Temporary ASP.NET Files'
    Get-ChildItem $aspNetTempFolder | Select-Object -Exp FullName
}