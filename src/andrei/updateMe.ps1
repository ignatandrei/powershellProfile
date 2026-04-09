function updateMe() {
# Ensure the profile directory exists, then download the latest unified profile
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Force -Path $profileDir | Out-Null }

# Backup existing profile if it exists
if (Test-Path $PROFILE) {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $backupPath = [System.IO.Path]::Combine($profileDir, [System.IO.Path]::GetFileNameWithoutExtension($PROFILE) + ".$timestamp" + [System.IO.Path]::GetExtension($PROFILE))
    Copy-Item -Path $PROFILE -Destination $backupPath
    Write-Host "Backup created: $backupPath"
}

Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/ignatandrei/powershellProfile/main/dist/pws-profile.ps1" -OutFile $PROFILE
}
