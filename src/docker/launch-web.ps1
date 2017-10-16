param(
   [string]$projectName
)
$ErrorActionPreference='Stop'
$env:COMPOSE_PROJECT_NAME = $projectName

Write-Information 'Provisioning app...'
docker-compose up -d
Write-Information 'Provisioning app... DONE'

$ip = docker container inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$($projectName)_nerd-dinner-web_1"
$url = "http:\\$ip"

$tryRequest = {
    try {
        return (Invoke-WebRequest $url -UseBasicParsing).StatusCode
    }
    catch [System.Net.WebException] {
        return $_.Exception.Response.StatusCode
    }
    catch {
        return $null
    }
}

$attempt = 1
$status = $null
while ($attempt -le 5) {
    Write-Information "Testing if app is ready (attempt $attempt)"
    $status = & $tryRequest
    $attempt++
    Write-Information "App returned status code: $status"
    if ($status -ne 200) {
        Start-Sleep -Seconds 15
    } else {
        break
    }
}

if ($status -ne 200) {
    throw "App not yet available, try again in a minute"
}

Write-Information "Opening '$url' in chrome"
Start-Process  chrome.exe -ArgumentList @( '-incognito', $url )
Write-Host '**Tip** Use the following command to stop and teardown app:'
Write-Host "`t docker-compose down -v" -ForegroundColor Magenta