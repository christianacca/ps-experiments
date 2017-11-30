@{ 
    PSDependOptions     = @{ Target = 'C:\Scrap\powershell' } 
    DemoRequiredModule  = '1.0.0'
    DemoRequiringModule = @{
        Version   = '1.0.0'
        DependsOn = 'DemoRequiredModule'
    }
    PostInstallFix      = @{
        DependencyType = 'Command'
        Source         = 'Remove-ExcessInstalledModules `$DependencyPath'
    }
}