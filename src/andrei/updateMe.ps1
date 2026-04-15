function updateMe() {
<#
.SYNOPSIS
Downloads the latest pws-profile.ps1 from GitHub next to your $PROFILE and ensures your profile dot-sources it.

.DESCRIPTION
Downloads the latest unified profile from the ignatandrei/powershellProfile repository on GitHub
and saves it as pws-profile.ps1 in the same directory as $PROFILE (backing up any existing copy
with a timestamped filename). It then checks whether $PROFILE already dot-sources pws-profile.ps1
and adds the dot-source line if it is missing.

.EXAMPLE
updateMe
Downloads the latest pws-profile.ps1 next to $PROFILE, backs up the old copy, and ensures $PROFILE includes it.
#>
# Ensure the profile directory exists
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Force -Path $profileDir | Out-Null }

$pwsFile = Join-Path $profileDir 'pws-profile.ps1'

# Backup existing pws-profile.ps1 if it exists
if (Test-Path $pwsFile) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $backupPath = Join-Path $profileDir "pws-profile.$timestamp.ps1"
    Copy-Item -Path $pwsFile -Destination $backupPath
    Write-Host "Backup created: $backupPath"
}

# Download the latest unified profile next to $PROFILE
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/ignatandrei/powershellProfile/main/dist/pws-profile.ps1" -OutFile $pwsFile
Write-Host "Downloaded to: $pwsFile"

# Ensure $PROFILE file exists
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Force -Path $PROFILE | Out-Null
}

# Add dot-source line to $PROFILE if not already present
$escapedPwsFile = $pwsFile -replace "'", "''"
$includeLine = ". '$escapedPwsFile'"
$profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
if (-not ($profileContent -match ('(?m)^\s*\.\s+.*' + [regex]::Escape('pws-profile.ps1')))) {
    Add-Content -Path $PROFILE -Value ([Environment]::NewLine + $includeLine)
    Write-Host "Added include to: $PROFILE"
} else {
    Write-Host "Profile already includes pws-profile.ps1"
}
}
