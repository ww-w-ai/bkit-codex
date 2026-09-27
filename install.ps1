# install.ps1 - bkit-codex project installer for Windows
# Installs bkit-codex into the current project directory or globally.
# Usage:
#   irm https://raw.githubusercontent.com/ww-w-ai/bkit-codex/main/install.ps1 | iex
#   .\install.ps1 [-Global] [-Uninstall] [-Version] [-Force] [-Help]

param(
    [switch]$Global,
    [switch]$Uninstall,
    [switch]$Version,
    [switch]$Force,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$Repo = "ww-w-ai/bkit-codex"
$BkitVersion = "1.0.1"

# When piped via iex, params aren't available. Detect via args:
if ($args -contains "--global")    { $Global = $true }
if ($args -contains "--uninstall") { $Uninstall = $true }
if ($args -contains "--version")   { $Version = $true }
if ($args -contains "--force")     { $Force = $true }
if ($args -contains "--help")      { $Help = $true }

# ── Color helpers ──────────────────────────────────────────────────────────────

function Write-Info  { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "[OK]   $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow }
function Write-Fail  { param([string]$Msg) Write-Host "[FAIL] $Msg" -ForegroundColor Red }

# ── UTF-8 helper (BOM-free for PS 5.1 compatibility) ──────────────────────────

function Set-Utf8Content {
    param([string]$Path, [string]$Content)
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $fullPath = if (Test-Path $Path) { (Resolve-Path $Path).Path } else { Join-Path (Get-Location) $Path }
    [System.IO.File]::WriteAllText($fullPath, $Content, $utf8NoBom)
}

function Add-Utf8Content {
    param([string]$Path, [string]$Content)
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $fullPath = (Resolve-Path $Path).Path
    $existing = [System.IO.File]::ReadAllText($fullPath, $utf8NoBom)
    [System.IO.File]::WriteAllText($fullPath, $existing + $Content, $utf8NoBom)
}

# ── Admin detection (PS-07) ───────────────────────────────────────────────────

$isAdmin = $false
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {
    # Non-Windows or restricted environment, ignore
}
if ($isAdmin) {
    Write-Warn "Running as Administrator - file ownership may change. Consider running as a normal user."
}

# ── Path resolution ───────────────────────────────────────────────────────────

if ($Global -or ($Uninstall -and -not (Test-Path ".bkit-codex") -and (Test-Path "$HOME\.bkit-codex"))) {
    $SkillsDir = Join-Path $HOME ".agents\skills"
    $ConfigDir = Join-Path $HOME ".codex"
    $ConfigFile = Join-Path $HOME ".codex\config.toml"
    $InstallDir = Join-Path $HOME ".bkit-codex"
    $InstallMode = "global"
} else {
    $SkillsDir = ".agents\skills"
    $ConfigDir = ".codex"
    $ConfigFile = ".codex\config.toml"
    $InstallDir = ".bkit-codex"
    $InstallMode = "project"
}

# ── Help ──────────────────────────────────────────────────────────────────────

function Show-Help {
    Write-Host @"
bkit-codex installer (Windows)

Usage:
  .\install.ps1 [options]

Options:
  -Global       Install to ~/.agents/skills/ and ~/.codex/ (user-level)
  -Uninstall    Remove bkit-codex installation
  -Version      Show installed version
  -Force        Overwrite AGENTS.md even if modified
  -Help         Show this help message

Examples:
  # Project-level install (default)
  irm https://raw.githubusercontent.com/ww-w-ai/bkit-codex/main/install.ps1 | iex

  # Global install
  .\install.ps1 -Global

  # Uninstall
  .\install.ps1 -Uninstall
"@
}

# ── Version ───────────────────────────────────────────────────────────────────

function Show-Version {
    $versionFile = Join-Path $InstallDir ".installed-version"
    if (Test-Path $versionFile) {
        $ver = Get-Content $versionFile -Raw
        Write-Host "bkit-codex v$($ver.Trim())"
    } elseif (Test-Path (Join-Path $InstallDir "packages\mcp-server\package.json")) {
        try {
            $pkg = Get-Content (Join-Path $InstallDir "packages\mcp-server\package.json") -Raw | ConvertFrom-Json
            Write-Host "bkit-codex v$($pkg.version)"
        } catch {
            Write-Host "bkit-codex v(unknown)"
        }
    } else {
        Write-Host "bkit-codex: not installed"
    }
}

# ── File hash helper ──────────────────────────────────────────────────────────

function Get-FileHash256 {
    param([string]$Path)
    if (Test-Path $Path) {
        return (Get-FileHash -Path $Path -Algorithm MD5).Hash
    }
    return ""
}

# ── Validate installation ────────────────────────────────────────────────────

function Test-Installation {
    $errors = 0
    Write-Info "Validating installation..."

    # Check skill links
    if (Test-Path $SkillsDir) {
        $skills = Get-ChildItem -Path $SkillsDir -Directory -ErrorAction SilentlyContinue
        foreach ($skill in $skills) {
            $skillMd = Join-Path $skill.FullName "SKILL.md"
            if (-not (Test-Path $skillMd)) {
                Write-Fail "Missing SKILL.md in: $($skill.Name)"
                $errors++
            }
        }
        $skillCount = $skills.Count
        if ($skillCount -ge 20) {
            Write-Ok "$skillCount skills linked"
        } else {
            Write-Warn "Only $skillCount skills found (expected 27)"
        }
    }

    # Check MCP server
    $mcpPath = Join-Path $InstallDir "packages\mcp-server\index.js"
    if ((Test-Path $mcpPath) -and (Get-Command node -ErrorAction SilentlyContinue)) {
        try {
            $initReq = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","clientInfo":{"name":"test","version":"1.0.0"}}}'
            $response = $initReq | node $mcpPath 2>$null | Select-Object -First 1
            if ($response -match "protocolVersion") {
                Write-Ok "MCP server responds correctly"
            } else {
                Write-Warn "MCP server did not respond (requires node >= 18)"
            }
        } catch {
            Write-Warn "MCP server check failed: $_"
        }
    } elseif (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Warn "Node.js not found - MCP server requires node >= 18"
    }

    # Check config.toml
    if ((Test-Path $ConfigFile) -and (Select-String -Path $ConfigFile -Pattern "mcp_servers.bkit" -Quiet)) {
        Write-Ok "MCP configuration present"
    } else {
        Write-Fail "MCP configuration missing from $ConfigFile"
        $errors++
    }

    # Check AGENTS.md
    if ($InstallMode -eq "project" -and (Test-Path "AGENTS.md")) {
        Write-Ok "AGENTS.md present"
    } elseif ($InstallMode -eq "global") {
        Write-Ok "Global install (AGENTS.md is project-specific)"
    }

    if ($errors -eq 0) {
        Write-Ok "All validations passed"
    } else {
        Write-Fail "$errors validation error(s) found"
    }

    return $errors
}

# ── Uninstall ─────────────────────────────────────────────────────────────────

function Invoke-Uninstall {
    Write-Info "Uninstalling bkit-codex ($InstallMode mode)..."

    # Remove skill links (only bkit-codex ones)
    if (Test-Path $SkillsDir) {
        $removed = 0
        $items = Get-ChildItem -Path $SkillsDir -Directory -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            # Check if it's a junction/symlink pointing to bkit-codex
            $target = ""
            try {
                $target = (Get-Item $item.FullName -Force).Target
            } catch {}
            if (-not $target) {
                try { $target = [System.IO.Path]::GetFullPath((cmd /c "dir /al $($item.FullName)" 2>$null | Select-String "\[" | ForEach-Object { $_ -replace '.*\[(.+)\].*', '$1' })) } catch {}
            }
            if ($target -match "bkit-codex") {
                Remove-Item $item.FullName -Force -Recurse
                $removed++
            }
        }
        Write-Ok "Removed $removed skill links"
        # Clean up empty dirs
        if ((Get-ChildItem $SkillsDir -ErrorAction SilentlyContinue).Count -eq 0) {
            Remove-Item $SkillsDir -Force -ErrorAction SilentlyContinue
            if ($InstallMode -eq "project") {
                Remove-Item ".agents" -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Remove MCP config entry
    if (Test-Path $ConfigFile) {
        $lines = Get-Content $ConfigFile
        $newLines = @()
        $skip = $false
        foreach ($line in $lines) {
            if ($line -match '^\[mcp_servers\.bkit\]') {
                $skip = $true
                continue
            }
            if ($skip -and $line -match '^\[') {
                $skip = $false
            }
            if (-not $skip) {
                $newLines += $line
            }
        }
        # Remove trailing blank lines
        while ($newLines.Count -gt 0 -and $newLines[-1].Trim() -eq "") {
            $newLines = $newLines[0..($newLines.Count - 2)]
        }
        if ($newLines.Count -gt 0) {
            Set-Utf8Content -Path $ConfigFile -Content ($newLines -join "`n")
            Write-Ok "Removed MCP config from $ConfigFile"
        } else {
            Remove-Item $ConfigFile -Force -ErrorAction SilentlyContinue
            if ((Get-ChildItem $ConfigDir -ErrorAction SilentlyContinue).Count -eq 0) {
                Remove-Item $ConfigDir -Force -ErrorAction SilentlyContinue
            }
            Write-Ok "Removed empty $ConfigDir/"
        }
    } else {
        Write-Warn "No config file found at $ConfigFile"
    }

    # Remove clone directory
    if (Test-Path $InstallDir) {
        Remove-Item $InstallDir -Recurse -Force
        Write-Ok "Removed: $InstallDir"
    } else {
        Write-Warn "Install directory not found: $InstallDir"
    }

    Write-Host ""
    Write-Warn "AGENTS.md, docs/, .gitignore left intact (may contain user data)"
    Write-Info "Uninstall complete"
}

# ── Install ───────────────────────────────────────────────────────────────────

function Invoke-Install {
    Write-Host ""
    Write-Info "Installing bkit-codex ($InstallMode mode)..."
    Write-Host ""

    # ── Step 1: Clone or update repository ────────────────────────────────

    if (Test-Path $InstallDir) {
        Write-Info "Updating existing installation..."
        try {
            git -C $InstallDir pull --ff-only 2>$null
            Write-Ok "Repository updated"
        } catch {
            Write-Warn "git pull failed (offline?)"
        }
    } else {
        Write-Info "Cloning repository..."
        git clone --depth 1 "https://github.com/$Repo.git" $InstallDir
        Write-Ok "Cloned to $InstallDir"
    }

    # Save installed version
    $pkgFile = Join-Path $InstallDir "packages\mcp-server\package.json"
    $ver = "unknown"
    if (Test-Path $pkgFile) {
        try {
            $pkg = Get-Content $pkgFile -Raw | ConvertFrom-Json
            $ver = $pkg.version
        } catch {}
    }
    Set-Utf8Content -Path (Join-Path $InstallDir ".installed-version") -Content $ver

    # ── Step 2: Create skill symlinks ─────────────────────────────────────

    if (-not (Test-Path $SkillsDir)) {
        New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
    }

    $linked = 0
    $skipped = 0
    $sourceSkillsDir = Join-Path $InstallDir ".agents\skills"
    $sourceSkills = Get-ChildItem -Path $sourceSkillsDir -Directory -ErrorAction SilentlyContinue

    foreach ($skill in $sourceSkills) {
        $targetPath = Join-Path $SkillsDir $skill.Name
        if (Test-Path $targetPath) {
            $skipped++
        } else {
            # Prefer symbolic link with relative path; fallback to junction
            try {
                $relativePath = [System.IO.Path]::GetRelativePath(
                    (Resolve-Path $SkillsDir).Path,
                    $skill.FullName
                )
                New-Item -ItemType SymbolicLink -Path $targetPath -Target $relativePath -ErrorAction Stop | Out-Null
                $linked++
            } catch {
                # SymbolicLink may require admin; fallback to junction (absolute path)
                try {
                    cmd /c mklink /J $targetPath $skill.FullName 2>$null | Out-Null
                    $linked++
                } catch {
                    Write-Fail "Failed to link: $($skill.Name)"
                }
            }
        }
    }
    Write-Ok "Skills: $linked linked, $skipped already present"

    # ── Step 3: AGENTS.md (project-level only) ────────────────────────────

    if ($InstallMode -eq "project") {
        $sourceAgents = Join-Path $InstallDir "AGENTS.md"
        if (-not (Test-Path "AGENTS.md")) {
            Copy-Item $sourceAgents "AGENTS.md"
            Write-Ok "Created: AGENTS.md"
        } elseif ($Force) {
            Copy-Item $sourceAgents "AGENTS.md" -Force
            Write-Ok "Overwritten: AGENTS.md (-Force)"
        } else {
            $currentHash = Get-FileHash256 "AGENTS.md"
            $sourceHash = Get-FileHash256 $sourceAgents
            if ($currentHash -eq $sourceHash) {
                Write-Ok "AGENTS.md is up to date"
            } else {
                Write-Warn "AGENTS.md differs from source (use -Force to overwrite)"
            }
        }
    }

    # ── Step 4: Configure MCP server ──────────────────────────────────────

    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
    }

    # Determine MCP path (global mode must use absolute paths so codex
    # can find the MCP server regardless of the working directory)
    if ($InstallMode -eq "global") {
        $absolutePath = [System.IO.Path]::GetFullPath($InstallDir) -replace '\\', '/'
        $mcpArgs = "[`"$absolutePath/packages/mcp-server/index.js`"]"
    } else {
        $mcpArgs = '["./.bkit-codex/packages/mcp-server/index.js"]'
    }

    $mcpConfig = @"

# bkit-codex MCP server (PDCA methodology automation)
[mcp_servers.bkit]
command = "node"
args = $mcpArgs
startup_timeout_sec = 10
tool_timeout_sec = 60
required = true
"@

    if (-not (Test-Path $ConfigFile)) {
        Set-Utf8Content -Path $ConfigFile -Content $mcpConfig.TrimStart()
        Write-Ok "Created: $ConfigFile"
    } elseif (-not (Select-String -Path $ConfigFile -Pattern "mcp_servers.bkit" -Quiet)) {
        Add-Utf8Content -Path $ConfigFile -Content $mcpConfig
        Write-Ok "Updated: $ConfigFile (added bkit MCP)"
    } else {
        # Check if timeout needs update
        if (Select-String -Path $ConfigFile -Pattern "tool_timeout_sec = 30" -Quiet) {
            $content = [System.IO.File]::ReadAllText((Resolve-Path $ConfigFile).Path)
            $content = $content -replace "tool_timeout_sec = 30", "tool_timeout_sec = 60"
            Set-Utf8Content -Path $ConfigFile -Content $content
            Write-Ok "Updated: $ConfigFile (tool_timeout_sec 30 -> 60)"
        } else {
            Write-Ok "MCP config already present"
        }
    }

    # ── Step 5: Initialize PDCA directories (project-level only) ──────────

    if ($InstallMode -eq "project") {
        $pdcaDirs = @(
            "docs\01-plan\features",
            "docs\02-design\features",
            "docs\03-analysis",
            "docs\04-report"
        )
        foreach ($dir in $pdcaDirs) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Force -Path $dir | Out-Null
            }
        }
        Write-Ok "PDCA directories ready"
    }

    # ── Step 6: Update .gitignore (project-level only) ────────────────────

    if ($InstallMode -eq "project") {
        if (Test-Path ".gitignore") {
            $content = Get-Content ".gitignore" -Raw -ErrorAction SilentlyContinue
            if ($content -notmatch "\.bkit-codex/") {
                $appendLines = @("", "# bkit-codex", ".bkit-codex/", "")
                Add-Utf8Content -Path ".gitignore" -Content ($appendLines -join [Environment]::NewLine)
                Write-Ok "Updated: .gitignore"
            } else {
                Write-Ok ".gitignore already configured"
            }
        } else {
            $newLines = @("# bkit-codex", ".bkit-codex/", "")
            Set-Utf8Content -Path ".gitignore" -Content ($newLines -join [Environment]::NewLine)
            Write-Ok "Created: .gitignore"
        }
    }

    # ── Step 7: Post-install validation ───────────────────────────────────

    Write-Host ""
    $null = Test-Installation

    # ── Summary ───────────────────────────────────────────────────────────

    Write-Host ""
    Write-Info "bkit-codex v$ver installed successfully! ($InstallMode mode)"
    $totalSkills = (Get-ChildItem -Path $SkillsDir -Directory -ErrorAction SilentlyContinue).Count
    Write-Host "  Skills:     $totalSkills linked"
    Write-Host "  MCP Server: configured in $ConfigFile"
    if ($InstallMode -eq "project") {
        Write-Host "  PDCA Docs:  docs/ directory ready"
    }
    Write-Host ""
    Write-Host 'Start Codex and type $pdca to begin!'
}

# ── Main dispatch ─────────────────────────────────────────────────────────────

if ($Help) {
    Show-Help
} elseif ($Version) {
    Show-Version
} elseif ($Uninstall) {
    Invoke-Uninstall
} else {
    Invoke-Install
}
