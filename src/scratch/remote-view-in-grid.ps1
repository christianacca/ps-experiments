#Enter-PSSession -ComputerName 51.140.82.60 -Port 5985 -Credential (Get-Credential)

<# Executes powershell query against a remote host #>
$cred = Get-Credential
$cmd = {
    Get-Process | select ProcessName, CPU, WorkingSet -First 10    
}
Invoke-Command -ComputerName 51.140.82.60 -Port 5985 -Credential $cred -ScriptBlock $cmd |
Out-GridView
#ConvertTo-Json | clip; start http://jsonviewer.stack.hu/

<# Executes powershell query against a remote docker host and displays the results in ps grid #>
cd C:\Docker\w16-dk01
.\set-env.ps1
$cmd = {
    Get-Process | select ProcessName, CPU, WorkingSet -First 10 | ConvertTo-Json    
}
Invoke-Command { docker exec hc powershell "$cmd" } |
ConvertFrom-Json | foreach { [PSCustomObject]$_} | Out-GridView
#clip; start http://jsonviewer.stack.hu/