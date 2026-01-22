# Install Docker containers using "docker compose".
New-Item -ItemType Directory -Path Elasticsearch
Set-Location Elasticsearch
Copy-Item (Join-Path $PSScriptRoot docker-compose.yml) .
docker compose up --wait
docker compose start

# Test server status.
function Test-Elasticsearch()
{
    try
    {
        $result = Invoke-WebRequest http://localhost:9200/
        Write-Output $result
        return $true
    }
    catch
    {
        return $false
    }
}

for ($i = 0; $i -lt 10; $i += 1)
{
    if (Test-Elasticsearch)
    {
        Write-Output ok
        break
    }
    else
    {
        Write-Output 'Wait a few seconds!'
        Start-Sleep -Seconds 3
    }
}