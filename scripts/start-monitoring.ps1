# PowerShell script to start the release monitoring
# Works on Windows

# Navigate to the project root directory
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "Starting release monitoring from $projectRoot..."

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "Docker is running."
} catch {
    Write-Host "Error: Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Check if the app monitoring stack is running
$monitoringNetwork = docker network ls --filter "name=monitoring-network" --format "{{.Name}}"
if (-not $monitoringNetwork) {
    Write-Host "Warning: The monitoring network doesn't exist. Make sure the app monitoring stack is running." -ForegroundColor Yellow
    Write-Host "Starting the app monitoring stack first..."
    
    # Try to start the app monitoring stack
    $appMonitoringPath = Join-Path (Split-Path -Parent $projectRoot) "fastAPI-project-app"
    if (Test-Path $appMonitoringPath) {
        Set-Location $appMonitoringPath
        & docker-compose -f docker-compose.monitoring-only.yml up -d
        Set-Location $projectRoot
    } else {
        Write-Host "Error: Could not find the app repository. Please start the app monitoring stack manually." -ForegroundColor Red
        exit 1
    }
}

# Start the release monitoring
Write-Host "Starting release monitoring services..."
docker-compose -f docker-compose.monitoring.yml up -d

# Check if services are running
Write-Host "Checking if services are running..."
$status = docker ps --filter "name=release-monitoring" --format "{{.Status}}"
if ($status) {
    Write-Host "Release monitoring is running: $status" -ForegroundColor Green
} else {
    Write-Host "Release monitoring is not running" -ForegroundColor Yellow
}

Write-Host "Release monitoring setup complete."
Write-Host "You can access the monitoring dashboards at:"
Write-Host "- Grafana: http://localhost:3001"
