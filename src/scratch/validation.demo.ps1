function Test-Func {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ParameterSetName='Enabled')]
        [switch]$Enable,
        [Parameter(Mandatory, ParameterSetName='Disabled')]
        [switch]$Disable
    )
    if ($Enable.IsPresent -and $PSCmdlet.ShouldProcess('Resource', 'Enable')) {
        Write-Verbose "Enabling resource"
    }
    
    if ($Disable.IsPresent -and $PSCmdlet.ShouldProcess('Resource', 'Disable')) {
        Write-Verbose "Disabling resource"
    }
}
Clear-Host

Test-Func -Enable -WhatIf