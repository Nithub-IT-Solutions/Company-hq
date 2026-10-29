$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
    throw "Run this script from inside the Company-hq Git repository."
}
$settingsPath = Join-Path $repoRoot.Trim() ".claude\settings.local.json"
$expectedCeo = "nisarmohammadTPM"
$expectedBot = "nithubceoai"
$failed = $false

function Invoke-GhRequest {
    param(
        [string]$Token,
        [string[]]$Arguments
    )

    $names = @("GH_TOKEN", "GITHUB_TOKEN", "GH_ENTERPRISE_TOKEN")
    $previous = @{}
    foreach ($name in $names) {
        $previous[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
        [Environment]::SetEnvironmentVariable($name, $null, "Process")
    }
    if ($Token) {
        $env:GH_TOKEN = $Token
    }

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    try {
        $ghPath = (Get-Command gh).Source
        $process = Start-Process `
            -FilePath $ghPath `
            -ArgumentList $Arguments `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath
        if ($process.ExitCode -ne 0) {
            return $null
        }
        return (Get-Content $stdoutPath -Raw).Trim()
    } finally {
        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
        foreach ($name in $names) {
            [Environment]::SetEnvironmentVariable($name, $previous[$name], "Process")
        }
    }
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "FAIL GitHub CLI (gh) is not installed or is not on PATH."
    exit 1
}

$ceoLogin = Invoke-GhRequest -Arguments @("api", "user", "--jq", ".login")
if ($ceoLogin -eq $expectedCeo) {
    Write-Host "PASS GitHub CLI is authenticated as CEO ($expectedCeo)."
} else {
    Write-Host "FAIL GitHub CLI must be authenticated as $expectedCeo (found: $ceoLogin)."
    $failed = $true
}

if (-not (Test-Path $settingsPath)) {
    Write-Host "FAIL Local Claude settings are missing: $settingsPath"
    Write-Host "Copy .claude/settings.local.json.example to .claude/settings.local.json and add the bot token."
    $failed = $true
} else {
    try {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "FAIL Local Claude settings are not valid JSON."
        exit 1
    }
    $token = $settings.env.GH_TOKEN
    if (-not $token -or $token -like "PASTE_*") {
        Write-Host "FAIL Local Claude settings do not contain a bot GitHub token."
        $failed = $true
    } else {
        $botLogin = Invoke-GhRequest -Token $token -Arguments @("api", "user", "--jq", ".login")
        if ($botLogin -eq $expectedBot) {
            Write-Host "PASS Local bot GitHub token authenticates as $expectedBot."
            $canPush = Invoke-GhRequest `
                -Token $token `
                -Arguments @("api", "repos/Nithub-IT-Solutions/Company-hq", "--jq", ".permissions.push")
            if ($canPush -eq "true") {
                Write-Host "PASS Bot token has push access to Company HQ."
            } else {
                Write-Host "FAIL Bot token lacks push access to Company HQ."
                $failed = $true
            }
            $projectAccess = Invoke-GhRequest `
                -Token $token `
                -Arguments @("project", "list", "--owner", "Nithub-IT-Solutions", "--limit", "1", "--format", "json")
            if ($null -ne $projectAccess) {
                Write-Host "PASS Bot token can access the organization Projects API."
            } else {
                Write-Host "FAIL Bot token cannot access the organization Projects API."
                $failed = $true
            }
        } elseif ($botLogin) {
            Write-Host "FAIL Local bot GitHub token authenticates as $botLogin, not $expectedBot."
            $failed = $true
        } else {
            Write-Host "FAIL Local bot GitHub token was rejected or lacks access."
            $failed = $true
        }
    }

    if (
        $settings.env.GIT_AUTHOR_NAME -eq $expectedBot -and
        $settings.env.GIT_COMMITTER_NAME -eq $expectedBot -and
        $settings.env.GIT_AUTHOR_EMAIL -eq "347468245+nithubceoai@users.noreply.github.com" -and
        $settings.env.GIT_COMMITTER_EMAIL -eq "347468245+nithubceoai@users.noreply.github.com"
    ) {
        Write-Host "PASS Claude Code commits are attributed to the bot account."
    } else {
        Write-Host "FAIL Configure Claude Code Git author and committer as $expectedBot with its GitHub noreply email."
        $failed = $true
    }
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "FAIL Claude Code CLI is not installed or is not on PATH."
    $failed = $true
} else {
    $authOutput = & claude auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        try {
            $auth = ($authOutput -join "`n") | ConvertFrom-Json
            if ($auth.loggedIn -and $auth.authMethod -eq "claude.ai") {
                Write-Host "PASS Claude Code is signed in to Claude.ai."
            } else {
                Write-Host "FAIL Claude Code does not report an active Claude.ai login."
                $failed = $true
            }
        } catch {
            Write-Host "FAIL Claude Code returned an unreadable authentication status."
            $failed = $true
        }
    } else {
        Write-Host "FAIL Claude Code is not authenticated."
        $failed = $true
    }
}

Write-Host "NOTE This does not validate the GitHub Actions CLAUDE_CODE_OAUTH_TOKEN secret."
Write-Host "NOTE Validate that secret with the credential-only workflow before running Discovery."

if ($failed) {
    exit 1
}
