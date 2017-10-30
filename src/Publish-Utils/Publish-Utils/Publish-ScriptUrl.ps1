<#
.SYNOPSIS
Publishes a powershell script fetched from a url

.DESCRIPTION
     Publishes a powershell script fetched from a url

#>
function Publish-ScriptUrl {

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
            
            $url = "$UrlPath/$scriptName"
            Invoke-WebRequest $url -UseBasicParsing |
                Select-Object -Exp Content |
                New-Item -Path $env:TEMP -Name $scriptName -ItemType File -Force -WhatIf:$false | Out-Null
                
            Publish-ScriptUrlHelper @PSBoundParameters
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}