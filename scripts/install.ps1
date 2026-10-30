$ErrorActionPreference = "Stop"
# 설치 위치는 D:\ 가 아니어도 됩니다. 스크립트 파일이 있는 폴더를 기준으로 찾습니다.
$Root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
Set-Location -LiteralPath $Root

function Invoke-Compose {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$ComposeArgs
    )
    & docker compose --project-directory $Root -f (Join-Path $Root "compose.yaml") @ComposeArgs
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose $($ComposeArgs -join ' ') failed."
    }
}

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
    Write-Host "Install folder: $Root"
    $envFile = Join-Path $Root ".env"
    if (-not (Test-Path -LiteralPath $envFile)) {
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
        [IO.File]::WriteAllLines($envFile, $config, [Text.Encoding]::ASCII)
        Write-Host "Created local credentials in .env. Keep this file private and backed up."
    }
    Invoke-Compose config --quiet
    $offline = Join-Path $Root "docker-images.tar"
    if (Test-Path -LiteralPath $offline) {
        docker load -i $offline
        if ($LASTEXITCODE -ne 0) { throw "Could not load offline images." }
        Invoke-Compose up -d --pull never
    } else {
        Invoke-Compose up -d
    }
    Invoke-Compose ps
    Write-Host "Started. Check N8N_PORT in .env (default: http://localhost:5678)."
    Write-Host "First startup can take a few minutes. Create your n8n owner account in the browser."
    Write-Host "pgAdmin: http://localhost:5050 (credentials are in .env)."
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
