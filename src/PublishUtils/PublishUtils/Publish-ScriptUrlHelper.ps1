<#
.SYNOPSIS
Helper to publish a powershell script fetched from a url

.DESCRIPTION
     Helper to publish a powershell script fetched from a url

#>
function Publish-ScriptUrlHelper {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$UrlPath,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        $Repository,

        [ValidateNotNullOrEmpty()]
        [string]$NuGetApiKey,

        [switch]$PassThru
    )
    
    begin {
        $callerEA = $ErrorActionPreference
    }
    
    process {
        $ErrorActionPreference = 'Stop'

        try {
            $scriptName = "$Name.ps1"
            $scriptPath = "$env:TEMP\$scriptName"
            
            try {
                $scriptInfo = Test-ScriptFileInfo -Path $scriptPath
                $publishParams = @{
                    Path       = $scriptPath
                    Repository = $Repository
                    WhatIf     = $false
                }
                if ($PSBoundParameters.ContainsKey('NuGetApiKey')) {
                    $publishParams['NuGetApiKey'] = $NuGetApiKey
                }
                if ($PSCmdlet.ShouldProcess($Repository, "Publishing script $scriptPath")) {
                    Publish-Script @publishParams
                }
                if ($PassThru) {
                    $scriptInfo
                }
            }
            finally {
                Remove-Item $scriptPath -WhatIf:$false
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}