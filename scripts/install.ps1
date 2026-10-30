$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
function New-Secret {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    return ([BitConverter]::ToString($bytes)).Replace("-", "").ToLowerInvariant()
}
try {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Install Docker Desktop from https://www.docker.com/products/docker-desktop/ then start it and run this installer again."
    }
    docker info --format '{{.OSType}}'
    if ($LASTEXITCODE -ne 0) { throw "Start Docker Desktop with Linux containers, then retry." }
    docker compose version
    if ($LASTEXITCODE -ne 0) { throw "Docker Compose is required. Update Docker Desktop." }
    if (-not (Test-Path .env)) {
        $config = @(
            "POSTGRES_USER=n8n"
            "POSTGRES_PASSWORD=$(New-Secret)"
            "POSTGRES_DB=n8n"
            "POSTGRES_PORT=5432"
            "N8N_PORT=5678"
            "N8N_ENCRYPTION_KEY=$(New-Secret)"
            "PGADMIN_EMAIL=admin@example.com"
            "PGADMIN_PASSWORD=$(New-Secret)"
        )
        [IO.File]::WriteAllLines((Join-Path (Get-Location) '.env'), $config, [Text.Encoding]::ASCII)
        Write-Host "Created local credentials in .env. Keep this file private and backed up."
    }
    docker compose config --quiet
    if ($LASTEXITCODE -ne 0) { throw "Invalid configuration. Check .env." }
    $offline = Join-Path (Get-Location) 'docker-images.tar'
    if (Test-Path $offline) {
        docker load -i $offline
        if ($LASTEXITCODE -ne 0) { throw "Could not load offline images." }
        docker compose up -d --pull never
    } else {
        docker compose up -d
    }
    if ($LASTEXITCODE -ne 0) { throw "Startup failed. Run docker compose logs --tail 100 to diagnose." }
    docker compose ps
    Write-Host "Started. Check N8N_PORT in .env (default: http://localhost:5678)."
    Write-Host "First startup can take a few minutes. Create your n8n owner account in the browser."
    Write-Host "pgAdmin: http://localhost:5050 (credentials are in .env)."
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
