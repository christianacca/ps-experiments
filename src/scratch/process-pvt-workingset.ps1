# Return the private working set (memory) of every process started in the last 1 minute
Get-Process | ? { $_.StartTime -gt (Get-Date).AddMinutes(-1) } | select -ExpandProperty Id |
% {
    Get-CimInstance -ClassName Win32_PerfFormattedData_PerfProc_Process -Filter "IdProcess = $_" |
        select IdProcess, Name, @{n = "Private_Working_Set"; e = {$_.workingSetPrivate / 1kb}}
}