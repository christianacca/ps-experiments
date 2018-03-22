$ErrorActionPreference = 'Stop'

$password = ConvertTo-SecureString 'SDfgsefgthsdhhearfgerg55472**!!' -AsPlainText -Force
$username = 'NodeTestUser'

# setup...

# create user
if (-not(Get-LocalUser $username -EA Ignore)) {
    New-LocalUser $username -Password $password
}

# MANUAL setup: add readonly permission for $username to $PSScriptRoot


# run node...

$jsFilePath = "$PSScriptRoot\simple.js"

$psi = [System.Diagnostics.ProcessStartInfo] @{ 
    RedirectStandardError  = $True
    RedirectStandardOutput = $True
    CreateNoWindow         = $true
    UseShellExecute        = $False
    UserName               = $username
    Domain                 = $env:COMPUTERNAME
    Password               = $password 
    FileName               = 'node.exe'  
    Arguments              = $jsFilePath
}

$process = [Diagnostics.Process]::Start($psi)
$process.StandardOutput.ReadToEnd() -replace "\r\n$", "" | Out-Default
$process.WaitForExit()

if ($process.ExitCode -gt 0) {
    $errorOutput = $process.StandardError.ReadToEnd()
    $errorMsg = "Error executing node$([System.Environment]::NewLine)"
    $errorMsg += "Exit code: $($process.ExitCode)$([System.Environment]::NewLine)"
    if (![string]::IsNullOrWhiteSpace($errorOutput)) {
        $errorMsg += "Error details:$([System.Environment]::NewLine)"
        $errorMsg += $errorOutput
    }
    throw [System.Exception]::new($errorMsg)
}