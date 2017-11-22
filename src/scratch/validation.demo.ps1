function Test-Func {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ParameterSetName='Enabled')]
        [switch]$Enable,
        [Parameter(Mandatory, ParameterSetName='Disabled')]
        [switch]$Disable,

        [Parameter(Mandatory)]
        [PsCustomObject] $RefValue
    )
    Write-Verbose $RefValue
    if ($Enable.IsPresent -and $PSCmdlet.ShouldProcess('Resource', 'Enable')) {
        Write-Verbose "Enabling resource"
    }
    
    if ($Disable.IsPresent -and $PSCmdlet.ShouldProcess('Resource', 'Disable')) {
        Write-Verbose "Disabling resource"
    }
}
Clear-Host

Test-Func -Enable -Verbose
Test-Func -Enable -RefValue $null -Verbose