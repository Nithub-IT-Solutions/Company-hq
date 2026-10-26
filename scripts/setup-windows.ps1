$ErrorActionPreference = "Stop"

function Test-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-Python312 {
    if (Test-Command "py") {
        & py -3.12 --version *> $null
        if ($LASTEXITCODE -eq 0) {
            return @{
                Command = "py"
                Prefix = @("-3.12")
            }
        }
    }

    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
        "$env:ProgramFiles\Python312\python.exe",
        "${env:ProgramFiles(x86)}\Python312\python.exe"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            $version = & $candidate --version 2>&1
            if ($LASTEXITCODE -eq 0 -and $version -match '^Python 3\.12\.') {
                return @{
                    Command = $candidate
                    Prefix = @()
                }
            }
        }
    }

    return $null
}

$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
    throw "Run this script from inside the Company-hq Git repository."
}
$repoRoot = $repoRoot.Trim()

$python = Get-Python312
if (-not $python) {
    if (-not (Test-Command "winget")) {
        throw "Python 3.12 is missing and winget is unavailable. Install Python 3.12 from python.org, then rerun this script."
    }

    Write-Host "Installing Python 3.12 with winget..."
    & winget install --id Python.Python.3.12 --exact --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget could not install Python 3.12. Review the install output and retry."
    }

    $python = Get-Python312
    if (-not $python) {
        throw "Python installation completed, but a Python 3.12 executable could not be found. Close and reopen PowerShell, then rerun this script."
    }
}

$pythonArgs = @($python.Prefix) + @("--version")
& $python.Command @pythonArgs
if ($LASTEXITCODE -ne 0) {
    throw "Python 3.12 was found but could not be run: $($python.Command)"
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
