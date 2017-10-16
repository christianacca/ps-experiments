Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

$iisAdminName = 'iisadmin'
try {
    $iisAdmin = Get-LocalUser $iisAdminName
    Write-Verbose "'$iisAdminName' user already exists"
}
catch {
    Write-Information "'$iisAdminName' user does not exist... creating now"
    $iisAdmin = New-LocalUser $iisAdminName `
        -Password (ConvertTo-SecureString '!!Sadmin*' -AsPlainText -Force) `
        -PasswordNeverExpires
}
$adminsMembers = Get-LocalGroupMember 'Administrators'
if ($adminsMembers.SID -notcontains $iisAdmin.SID) {
    Write-Information "Adding '$iisAdminName' user to local Administrators group"
    $adminsGroup = Get-LocalGroup 'Administrators'
    Add-LocalGroupMember $adminsGroup $iisAdmin
}

Write-Information "Enabling IIS remote administration for user '$iisAdminName'"
Import-Module servermanager
Add-WindowsFeature web-mgmt-service

Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\WebManagement\Server -Name EnableRemoteManagement -Value 1
Write-Information "Starting IIS remote management service"
Start-Service wmsvc