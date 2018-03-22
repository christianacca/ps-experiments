Describe 'Invoke-RestMethod' {

    It 'Get method - success' {
        $settings = Invoke-RestMethod http://series5/Spa/api/EnvironmentSettings
        $settings.isSsrsEnabled | Should -Be $false
    }
    
    
    It 'Get method - failure' {
        $startupUrl = 'http://series5/Spa/api/blah'
        try {
            Invoke-RestMethod $startupUrl -UseBasicParsing -EA Stop
        }
        catch {
            $erorResponse = $_.Exception.Response
            [int]$status = $erorResponse.StatusCode
            if ($status -ne 404) {
                # ignore errors - just want to cause iis to create a log
            } 
        }
    }
}