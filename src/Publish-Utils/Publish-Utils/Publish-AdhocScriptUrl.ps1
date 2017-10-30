<#
.SYNOPSIS
Publish the content of a powershell script identified by a url after first
appending script metadata

.DESCRIPTION
     Uses New-ScriptFileInfo to create a script file with script metadata.
     Adds to clipboard the content of powershell script identified by the url.
     Opens the script file in the powershell ISE where you can paste the 
     powershell code in clipboard, review and make changes before confirming
     the publish

#>
function Publish-AdhocScriptUrl {
    
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        $Author,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        $Version,

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
            
            $scriptInfo = @{
                Version     = $Version
                Author      = $Author
                Description = 'REPLACE ME'
            }
            
            New-ScriptFileInfo -Path $scriptPath @scriptInfo -Force
            ise $scriptPath
            
            $url = "$UrlPath/$scriptName"
            Invoke-WebRequest $url -UseBasicParsing | Select-Object -Exp Content | clip
            
            $userResponse = Read-Host "Enter 'y' if you want to publish the script"
            
            if ($userResponse -eq 'y') {
                $params = @{} + $PSBoundParameters
                $params.Remove('Author')
                $params.Remove('Version')
                Publish-ScriptUrlHelper @params
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}