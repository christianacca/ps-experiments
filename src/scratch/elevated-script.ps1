param([scriptblock] $Cmd)

New-Item -Path "$env:TEMP\runAsScript-$(New-Guid).ps1" -Value "$Cmd"  |
select -ExpandProperty FullName |
foreach { 
    Start-Process powershell.exe -ArgumentList "-noprofile -file $_" -Verb RunAs -Wait -WindowStyle Hidden
    $_ | Write-Output 
} |
Remove-Item