function Install-MissingModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string] $Repository,

        [Parameter(ParameterSetName = 'Name')]
        [switch] $Force,
        
        [Parameter(Mandatory, ParameterSetName = 'ScriptBlock')]
        [ScriptBlock] $ScriptBlock,

        [version] $RequiredVersion
    )
    
    begin {
        $callerEA = $ErrorActionPreference
    }
    
    process {
        try {
            if ((Get-InstalledModule -Name $Name -EA 'SilentlyContinue')) {
                Write-Verbose "Module $Name already installed... nothing to do"
                return;
            }

            Write-Verbose "Module $Name not found... installing now"
            switch ($PSCmdlet.ParameterSetName) {
                'Name' {
                    $installParams = @{} + $PSBoundParameters
                    Install-Module @installParams
                }
                'ScriptBlock' {
                    & $ScriptBlock
                }
                Default {
                    throw "ParameterSet '$($PSCmdlet.ParameterSetName)' not implementeds"
                }
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }

}