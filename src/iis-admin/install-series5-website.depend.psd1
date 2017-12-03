@{ 
    PSDependOptions     = @{ 
        Target = '$DependencyPath\dependencies'
    } 
    PreferenceVariables = '1.0'
    IISAdministration   = '1.1.0.0'
    HostNameUtils       = @{
        Version    = '1.0.0'
        Parameters = @{
            Repository = 'christianacca-ps'
        }
    }
    IISSecurity         = @{
        Version    = '0.1.0'
        DependsOn  = 'PreferenceVariables'
        Parameters = @{
            Repository = 'christianacca-ps'
        }
    }
    IISConfigUnlock     = @{
        Version    = '0.1.0'
        DependsOn  = @('IISAdministration', 'PreferenceVariables')
        Parameters = @{
            Repository = 'christianacca-ps'
        }
    }
    IISSiteInstall      = @{
        Version    = '0.1.0'
        DependsOn  = @('IISAdministration', 'PreferenceVariables', 'IISSecurity', 'HostNameUtils')
        Parameters = @{
            Repository = 'christianacca-ps'
        }
    }
    IISSeries5          = @{
        Version    = '0.1.0'
        DependsOn  = @('IISSiteInstall', 'PreferenceVariables')
        Parameters = @{
            Repository = 'christianacca-ps'
        }
    }   
    PostInstallFix      = @{
        DependencyType = 'Command'
        Source         = 'Remove-ExcessInstalledModules `$DependencyPath'
    }
}