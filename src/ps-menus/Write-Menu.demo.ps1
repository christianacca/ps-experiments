Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\Write-Menu.ps1"
. "$PSScriptRoot\Read-HostEnhanced.ps1"


$continue = Write-Menu -Menu 'Continue' -AddExit -Header 'Set SQL Id Offset contributor profile onto this machine?'
if ($continue -eq 'Exit')
{
    $false
    return
}


$exitPrompt = 'Use this (and exit)'
$selected = Write-Menu -Menu $exitPrompt, 'Create/select a profile' -Header "This machine already has a contributor profile for 'cc'"
if ($selected -eq $exitPrompt) {
    $true
    return
}


$Path = 'C:\sef\sefwef\verwererg'
$Path = if ($Path) {
    $choices = @(
        [PsCustomObject] @{
            Name = "Existing ('$Path')"
            Path = $Path
        }
        [PsCustomObject] @{
            Name = 'I will enter path'
            Path = ''
        }
    )
    $selected = Write-Menu -Menu $choices -Header 'Path to the central ID store'
    if ($selected -eq $choices[1]) {
        Read-HostEnhanced 'Enter path' -PromptColor Yellow -Shift 1
    } else {
        $selected.Path
    }
}
else
{
    Read-HostEnhanced -PromptColor Yellow -Title 'Path to the central ID store' -TitleColor Green -Shift 1
}
Write-Host "Using Path: $Path"

$contributorInitials = Read-HostEnhanced 'Enter your contributor initials (must match the prefix you use to name source control branches)' -PromptColor Green

$getCredential = {
    $username = Read-HostEnhanced 'Username' -Title 'Enter SQL database credentials' -PromptColor Yellow -TitleColor Green -Shift 1 -ValidateNotNull
    $password = Read-HostEnhanced 'Password' -AsSecureString -PromptColor Yellow -Shift 1
    [pscredential]::new($username, $password)
}

$credential = [PsCredential]::new('Series5Trusted', (ConvertTo-SecureString 'Crap' -AsPlainText -Force))
# $credential = $null
$selectedCredential = if ($credential) {
    $choices = @(
        $credential
        [PsCustomObject] @{
            UserName = 'I will enter credentials now'
        }
    )
    $selected = Write-Menu -Menu $choices -PropertyToShow UserName -Header 'Credentials to connect to the SQL database'
    if ($selected -eq $choices[1]) {
        & $getCredential
    } else {
        $selected
    }
}
else
{
    & $getCredential
}


$cancelPrompt = 'No... I might try again later'
$continue = Write-Menu -Menu 'Yes add me', $cancelPrompt -Header 'About to add you up as a contributor... confirm'
if ($continue -eq $cancelPrompt)
{
    $false
    return
}