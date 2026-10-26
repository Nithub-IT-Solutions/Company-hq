$ErrorActionPreference = "Stop"

function Test-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
    throw "Run this script from inside the Company-hq Git repository."
}
$repoRoot = $repoRoot.Trim()

$pythonReady = $false
if (Test-Command "py") {
    & py -3.12 --version *> $null
    $pythonReady = $LASTEXITCODE -eq 0
}

if (-not $pythonReady) {
    if (-not (Test-Command "winget")) {
        throw "Python 3.12 is missing and winget is unavailable. Install Python 3.12 from python.org, then rerun this script."
    }

    Write-Host "Installing Python 3.12 with winget..."
    & winget install --id Python.Python.3.12 --exact --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget could not install Python 3.12. Review the install output and retry."
    }

    if (-not (Test-Command "py")) {
        throw "Python was installed, but the Python launcher is not on this PowerShell PATH. Close and reopen PowerShell, then rerun this script."
    }
    & py -3.12 --version
    if ($LASTEXITCODE -ne 0) {
        throw "Python 3.12 is not available yet. Close and reopen PowerShell, then rerun this script."
    }
} else {
    & py -3.12 --version
}

Write-Host ""
Write-Host "Prerequisite checks:"
foreach ($command in @("git", "gh", "claude")) {
    if (Test-Command $command) {
        Write-Host "  Found $command"
    } else {
        Write-Warning "$command was not found. Follow Part A of SETUP-GUIDE.md to install it."
    }
}

$bashCandidates = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe"
)
$bashPath = $bashCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($bashPath) {
    Write-Host "  Found Git Bash: $bashPath"
} else {
    Write-Warning "Git Bash was not found. Install Git for Windows as described in Part A of SETUP-GUIDE.md."
}

Push-Location $repoRoot
try {
    git check-ignore --quiet ".claude/settings.local.json"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Local Claude settings are ignored by Git"
    } else {
        Write-Warning ".claude/settings.local.json is not ignored by Git; do not put a token in it."
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Python 3.12 is ready. This script does not configure GitHub access or handle tokens."
