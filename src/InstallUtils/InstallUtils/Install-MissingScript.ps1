function Install-MissingScript {
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
        [ScriptBlock] $ScriptBlock
    )
    
    begin {
        $callerEA = $ErrorActionPreference
    }
    
    process {
        try {
            if ((Get-InstalledScript -Name $Name -EA 'SilentlyContinue')) {
                Write-Verbose "Script $Name already installed... nothing to do"
                return;
            }

            Write-Verbose "Script $Name not found... installing now"
            switch ($PSCmdlet.ParameterSetName) {
                'Name' { 
                    if ($PSBoundParameters.ContainsKey('Repository')) {
                        Install-Script $Name -Repository $Repository -Force:$Force
                    }
                    else {
                        Install-Script $Name -Force:$Force
                    }
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