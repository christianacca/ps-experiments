function Get-IISSiteHostsFileEntry {
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param (
        [Parameter(ValueFromPipeline, ParameterSetName = 'Name', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(ValueFromPipeline, ParameterSetName = 'Object', Position = 0)]
        [Microsoft.Web.Administration.Site] $InputObject
        
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        $allEntries = @()
        $allEntries += Get-IISSiteHostsFileEntryHelper
    }
    
    process {
        try {

            $selectedSites = @()
            $selectedSites += if ($InputObject) {
                $InputObject
            }
            elseif (![string]::IsNullOrWhiteSpace($Name)) {
                Get-IISSite $Name
            }
            else {
                Get-IISSite
            }

            $siteEntries = $selectedSites | Get-IISSiteHostsFileEntryHelper

            $siteEntries | ForEach-Object {
                $entry = $_
                $isShared = ($allEntries | 
                        Where-Object Hostname -eq $entry.Hostname | 
                        Select-Object SiteName -Unique | Measure-Object).Count -gt 1
                $entry | Select-Object -Property *, @{ n='IsShared'; e={ $isShared }}
            }

        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}