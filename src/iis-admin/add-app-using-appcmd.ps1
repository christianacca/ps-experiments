$appcmd = "$env:windir\System32\inetsrv\appcmd.exe"

function Invoke-Exe {
    param([scriptblock] $Command)

    $ErrorActionPreference = 'Stop'

    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit code: $LASTEXITCODE)`n`rCommand: $Command"
    }
}

function Remove-IISSiteCmd {
    param(
        [string] $Name
    )

    $ErrorActionPreference = 'Stop'

    $sites = Invoke-Exe {
        & $appcmd list site /text:name
    }
    $siteExists = $sites | ? { $_ -eq $Name }
    if (-not($siteExists)) {
        return
    }

    Invoke-Exe {
        & $appcmd delete site $Name
    }
}

function Remove-IISAppPoolCmd {
    param(
        [string] $Name
    )

    $ErrorActionPreference = 'Stop'

    $pools = Invoke-Exe {
        & $appcmd list apppool /text:name
    }
    $poolExists = $pools | ? { $_ -eq $Name }
    if (-not($poolExists)) {
        return
    }

    Invoke-Exe {
        & $appcmd delete apppool $Name
    }
}


Clear-Host



# create dummy site so that our user will have a profile created in the registry (hack!)...

# todo: pass these as parameters to script
$domain = $env:COMPUTERNAME
$userName = 'HangfireLocalUser'
$domainQualifiedUserName = "$domain\$userName"
$password = '(pe&ter4powershell)'




$siteName = 'DummySite_OK-TO-DELETE'
Remove-IISSiteCmd $siteName

$poolName = 'Dummy-AppPool_OK-TO-DELETE'
Remove-IISAppPoolCmd $poolName


Invoke-Exe {
    & $appcmd add apppool /name:$poolName /managedRuntimeVersion:"v4.0" /managedPipelineMode:"Integrated" /startMode:"AlwaysRunning" `
        /processModel.identityType:"SpecificUser" /processModel.userName:`""$domainQualifiedUserName`"" /processModel.password:`""$password`""
    # & $appcmd set config /section:applicationPools "/[name='Dummy-AppPool'].processModel.identityType:SpecificUser" "/[name='Dummy-AppPool'].processModel.userName:'WIN10CCROWHURST\HangfireLocalUser'" "/[name='Dummy-AppPool'].processModel.password:(pe&ter4powershell)"
}

$sitePath = "C:\inetpub\$siteName"
if (-not(Test-Path $sitePath)) {
    New-Item $sitePath -ItemType Directory
}
Invoke-Exe {
    & $appcmd add site /name:$siteName /id:999 /bindings:http://DummySite:999 /physicalPath:"c:\inetpub\mynewsite"
}
Invoke-Exe {
    & $appcmd set app $siteName/ /applicationPool:$poolName
}


# set registry keys to enable app-insights dependency profiling...


# need to wait to allow IIS site above to start so that the registry entries for the user profile to be created
Start-Sleep -Seconds 2

$user = [System.Security.Principal.NTAccount]::new($domain, $userName)
$sid = $user.Translate([System.Security.Principal.SecurityIdentifier]).Value

[Microsoft.Win32.RegistryKey] $environKey = [Microsoft.Win32.Registry]::Users.OpenSubKey("$sid\Environment", $true)
$environKey.SetValue("COR_ENABLE_PROFILING", "1")
$environKey.SetValue("COR_PROFILER", "{324F817A-7420-4E6D-B3C1-143FBED6D855}")
$environKey.SetValue("MicrosoftInstrumentationEngine_Host", "{CA487940-57D2-10BF-11B2-A3AD5A13CBC0}")