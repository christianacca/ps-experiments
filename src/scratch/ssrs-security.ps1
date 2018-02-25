Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

function GetOrAddSsrsUser {
    param(
        [Parameter(Mandatory)]
        [string] $Name,
        [Parameter(Mandatory)]
        [string] $Password
    )
    $Name = $Name
    $user = try {
        Get-LocalUser $Name | Out-Null
        Write-Verbose "'$Name' user already exists"
    }
    catch {
        Write-Information "'$Name' user does not exist... creating now"
        New-LocalUser $Name `
            -Password (ConvertTo-SecureString $Password -AsPlainText -Force) `
            -PasswordNeverExpires
    }

    $user
}

# setup
GetOrAddSsrsUser 'SsrsUser' 'Asdqwdkjj!345rtfgbasdwdqwd**'
$toolsPath = 'C:\Git\Series5\src\Ram.Series5.Reports\tools'
if (-not(Test-Path $toolsPath)) {
    Save-Module -Name ReportingServicesTools -Path $toolsPath -RequiredVersion 0.0.4.4
}


# script...

$currentReportsPath = 'C:\Git\Series5\src\Ram.Series5.Reports\'
$ssrsUsername = 'BSW\ccrowhurst'
$modulePath = Join-Path $currentReportsPath 'tools\ReportingServicesTools'

Import-Module $modulePath
Connect-RsReportServer -ComputerName "localhost" -ReportServerInstance "SQL2008R2" -ReportServerUri http://localhost/reportserver_sql2008r2/

function TryAddSsrsPermission 
{
    param(
        [string] $RoleName,
        [scriptblock] $Script
    )

    try {
        & $Script
    }
    catch {
        if ($_ -notmatch 'existing role assignment for the current item' -and $_.ToString() -ne "$ssrsUsername already has $RoleName privileges") {
            Write-Error -ErrorRecord $_ -EA Stop
        }
    }
}

$roleName = 'System User'
TryAddSsrsPermission -RoleName $roleName {
    Grant-RsSystemRole -Identity $ssrsUsername -RoleName $roleName -Strict
}

$roleName = 'Content Manager'
TryAddSsrsPermission -RoleName $roleName {
    Grant-RsCatalogItemRole -Identity $ssrsUsername -RoleName $roleName -Path '/Ram.Series5/Test_Company' -Strict   
}

