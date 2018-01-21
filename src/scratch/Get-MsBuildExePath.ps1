function Get-MsBuildExePath {
    process {

        $path = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\" |
            Sort-Object {[double]$_.PSChildName} -Descending |
            Select-Object -First 1 |
            Get-ItemProperty -Name MSBuildToolsPath |
            Select -ExpandProperty MSBuildToolsPath

        $path = (Join-Path -Path $path -ChildPath 'msbuild.exe')

        return Get-Item $path
    }
}