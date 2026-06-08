# Runs BATS tests on Windows via Docker Desktop (preferred) or WSL2 (fallback).
# Prerequisites:
#   Docker Desktop — https://www.docker.com/products/docker-desktop
#   WSL2          — run 'wsl --install' in an admin PowerShell, then restart

param(
    [string]$TestPath = "tests/"
)

$ErrorActionPreference = "Stop"

function Test-CommandExists($name) {
    try { Get-Command $name -ErrorAction Stop | Out-Null; return $true }
    catch { return $false }
}

$repoRoot = $PSScriptRoot

# Docker Desktop (no extra setup needed — bats/bats image is self-contained)
if (Test-CommandExists "docker") {
    $dockerRunning = $false
    try {
        & docker version 2>&1 | Out-Null
        $dockerRunning = ($LASTEXITCODE -eq 0)
    } catch {}

    if ($dockerRunning) {
        Write-Host "Running tests via Docker Desktop..."
        & docker run --rm `
            --volume "${repoRoot}:/workspace" `
            --workdir /workspace `
            --entrypoint bash `
            bats/bats:latest `
            -c "chmod +x tests/mocks/* 2>/dev/null; bats --tap $TestPath"
        exit $LASTEXITCODE
    }
    else {
        Write-Warning "Docker is installed but not running. Start Docker Desktop and retry."
    }
}

# WSL2 fallback
if (Test-CommandExists "wsl") {
    Write-Host "Running tests via WSL2..."
    $env:WIN_REPO_PATH = $repoRoot
    & wsl bash -c @'
set -e
cd "$(wslpath "$WIN_REPO_PATH")"
if ! command -v bats &>/dev/null; then
    echo "Installing BATS..."
    sudo apt-get install -y bats -qq 2>/dev/null || {
        git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core
        sudo /tmp/bats-core/install.sh /usr/local
    }
fi
chmod +x tests/mocks/* 2>/dev/null || true
bats --tap tests/
'@
    exit $LASTEXITCODE
}

Write-Error @"

No test runner found. Install one of:

  Docker Desktop  https://www.docker.com/products/docker-desktop
  WSL2            run 'wsl --install' in an admin PowerShell, then restart

Then re-run:  .\run-tests.ps1
"@
exit 1
