# =============================================================================
# skills installer for Windows (PowerShell)
# =============================================================================
#   iwr -useb https://raw.githubusercontent.com/ab0t-com/skill-cli/main/install.ps1 | iex
#
# What it does (no admin required):
#   1. Detects arch and picks the published Windows artifact.
#   2. Downloads release/checksums.txt + the binary over HTTPS.
#   3. Verifies the published sha256 — mandatory; aborts on mismatch.
#   4. Installs to %LOCALAPPDATA%\Programs\skills\skills.exe (keeps .previous).
#   5. Adds that dir to your USER PATH (idempotent) and the current session.
#
# Note: skill *linking* (`skills setup`) uses symlinks. If it reports a symlink
# error, enable Developer Mode (Settings > Privacy and security > For developers)
# or run the shell elevated.
# =============================================================================
#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# `#Requires` above is ignored when this script is piped to `iex`, so enforce the
# minimum version at runtime too (avoids a cryptic failure on PowerShell <5).
if ($PSVersionTable.PSVersion.Major -lt 5) {
  throw "skills install.ps1 needs PowerShell 5.1+ (found $($PSVersionTable.PSVersion))."
}

# Windows PowerShell 5.1 defaults to TLS 1.0; GitHub requires TLS 1.2+. Force it
# or every download fails with an SSL error. (No-op/harmless on PowerShell 7+.)
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
# Invoke-WebRequest renders a progress bar that makes downloads ~10x slower on 5.1.
$ProgressPreference = 'SilentlyContinue'

$RepoRaw = if ($env:SKILL_REPO_RAW) { $env:SKILL_REPO_RAW } else { 'https://raw.githubusercontent.com/ab0t-com/skill-cli/main' }

# --- 1. platform -> artifact -------------------------------------------------
# ARM64 Windows runs the amd64 build under emulation, so map it to amd64 too.
switch ($env:PROCESSOR_ARCHITECTURE) {
  'AMD64' { $art = 'skills-windows-amd64.exe' }
  'ARM64' { $art = 'skills-windows-amd64.exe' }
  default { throw "no prebuilt Windows binary for arch '$($env:PROCESSOR_ARCHITECTURE)'. Build from source: github.com/ab0t-com/skill-cli" }
}

$tmp = Join-Path $env:TEMP ('skills-install-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
  # --- 2. fetch (HTTPS; TLS verification always on) --------------------------
  Write-Host 'fetching checksums...'
  Invoke-WebRequest -Uri "$RepoRaw/release/checksums.txt" -OutFile "$tmp\checksums.txt" -UseBasicParsing

  Write-Host "fetching $art..."
  Invoke-WebRequest -Uri "$RepoRaw/release/$art" -OutFile "$tmp\$art" -UseBasicParsing

  # --- 3. mandatory sha256 verification --------------------------------------
  # Strip any stray CR / BOM so the end-anchored match works regardless of line endings.
  $line = Get-Content "$tmp\checksums.txt" |
          ForEach-Object { $_ -replace '[\r﻿]', '' } |
          Where-Object { $_ -match ('\s' + [regex]::Escape($art) + '$') } |
          Select-Object -First 1
  if (-not $line) { throw "no checksum line for $art in checksums.txt" }
  $want = ($line.Trim() -split '\s+')[0].ToLower()
  $got  = (Get-FileHash -Algorithm SHA256 "$tmp\$art").Hash.ToLower()
  if ($got -ne $want) { throw "sha256 MISMATCH for $art (got $got, want $want) - refusing to install" }
  Write-Host 'sha256 verified.'

  # --- 4. install to a per-user dir (no admin) -------------------------------
  $dest = Join-Path $env:LOCALAPPDATA 'Programs\skills'
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  $exe = Join-Path $dest 'skills.exe'
  if (Test-Path $exe) { Move-Item -Force $exe "$exe.previous" }
  Move-Item -Force "$tmp\$art" $exe

  try { $ver = (& $exe --version) } catch { $ver = 'skills' }
  Write-Host ''
  Write-Host "[OK] installed $ver -> $exe"

  # --- 5. PATH (idempotent; [Environment] avoids setx's 1024-char truncation)-
  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not $userPath) { $userPath = '' }
  if (($userPath -split ';') -notcontains $dest) {
    $newPath = if ($userPath) { "$userPath;$dest" } else { $dest }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "added $dest to your user PATH (new terminals will have it)."
  }
  $env:Path = "$env:Path;$dest"   # usable in THIS session immediately

  Write-Host ''
  Write-Host 'Run this to finish (copy-paste):'
  Write-Host ''
  Write-Host '    skills setup'
  Write-Host ''
  Write-Host 'If setup reports a symlink error, enable Developer Mode'
  Write-Host '(Settings > Privacy and security > For developers) or run elevated.'
}
finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
