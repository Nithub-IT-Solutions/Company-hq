$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
    throw "Run this script from inside the Company-hq repository."
}
$repoRoot = $repoRoot.Trim()

$python = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
    & py -3.12 --version *> $null
    if ($LASTEXITCODE -eq 0) {
        $python = @{ Command = "py"; Prefix = @("-3.12") }
    }
}

if (-not $python) {
    $candidate = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
    if (Test-Path $candidate) {
        $version = & $candidate --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $version -match '^Python 3\.12\.') {
            $python = @{ Command = $candidate; Prefix = @() }
        }
    }
}

if (-not $python) {
    throw "Python 3.12 was not found. Run .\scripts\setup-windows.ps1 first."
}

Write-Host "Starting the local-only Company HQ dashboard."
Write-Host "The browser will open at http://127.0.0.1:8765"
Write-Host "Keep this window open. Press Ctrl+C to stop the dashboard."
Push-Location $repoRoot
try {
    $pythonArgs = @($python.Prefix) + @("dashboard\server.py")
    & $python.Command @pythonArgs
} finally {
    Pop-Location
}
