function Set-IISAppPoolUser {
    [CmdletBinding(DefaultParameterSetName='None')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'SpecificUser', Position = 0)]
        [PsCredential] $Credential,

        [Parameter(Mandatory, ParameterSetName = 'CommonIdentity', Position = 0)]
        [ValidateSet('ApplicationPoolIdentity', 'LocalService', 'LocalSystem', 'NetworkService')]
        [string] $IdentityType,

        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Microsoft.Web.Administration.ApplicationPool] $InputObject,
        
        [switch] $Commit
    )
    
    begin {
        Set-StrictMode -Version 'Latest'
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $callerEA = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        if (!$PSBoundParameters.ContainsKey('Commit')) {
            $Commit = $true
        }
    }
    
    process {
        try {

            if ($PSCmdlet.ParameterSetName -eq 'CommonIdentity') {
                $dummyPassword = ConvertTo-SecureString 'dummy' -AsPlainText -Force
                $username = ConvertTo-BuiltInUsername $IdentityType ($InputObject.Name)
                $Credential = [PsCredential]::new($username, $dummyPassword)
            }

            if ($Commit) {
                Start-IISCommitDelay
            }
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
                if ($Commit) {
                    Stop-IISCommitDelay
                }       
            }
            catch {
                if ($Commit) {
                    Stop-IISCommitDelay -Commit:$false
                }
                throw
            }
            finally {
                if ($Commit) {
                    # make sure subsequent scripts will not fail because the ServerManger is now readonly
                    Reset-IISServerManager -Confirm:$false
                }
            }

        }
        catch {
            Write-Error -ErrorRecord $_ -EA $callerEA
        }
    }
}