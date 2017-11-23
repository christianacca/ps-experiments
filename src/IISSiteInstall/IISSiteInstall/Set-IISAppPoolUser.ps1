function Set-IISAppPoolUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Microsoft.Web.Administration.ApplicationPool] $InputObject,

        [Parameter(Mandatory)]
        [PsCredential] $Credential
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
    }
    
    process {
        try {
            if ($Credential.UserName -like 'IIS AppPool\*'){
                $InputObject.ProcessModel.IdentityType = 'ApplicationPoolIdentity'
            } elseif($Credential.UserName -eq 'NT AUTHORITY\NETWORK SERVICE') {
                $InputObject.ProcessModel.IdentityType = 'NetworkService'
            } elseif ($Credential.UserName -eq 'NT AUTHORITY\SYSTEM') {
                $InputObject.ProcessModel.IdentityType = 'LocalSystem'
            } elseif ($Credential.UserName -eq 'NT AUTHORITY\LOCAL SERVICE') {
                $InputObject.ProcessModel.IdentityType = 'LocalService'
            } else {
                $InputObject.ProcessModel.UserName = $Credential.UserName
                $InputObject.ProcessModel.Password = $Credential.GetNetworkCredential().Password
                $InputObject.ProcessModel.IdentityType = 'SpecificUser'
            }
        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}