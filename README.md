# powershellProfile
A collection of utilities for PowerShell profile.

## Unified profile via CI

This repository contains multiple small `.ps1` utility files under `src/pws`. A GitHub Actions workflow concatenates them (alphabetically) into a single, ready-to-use profile script at `dist/pws-profile.ps1` on every push to `main` and also publishes it as a build artifact.

### First-time install

Run the following block **once** to download `pws-profile.ps1` next to your `$PROFILE` and wire it in automatically:

```powershell
# Ensure the profile directory exists
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Force -Path $profileDir | Out-Null }

# Download pws-profile.ps1 next to $PROFILE
$pwsFile = Join-Path $profileDir 'pws-profile.ps1'
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/ignatandrei/powershellProfile/main/dist/pws-profile.ps1" -OutFile $pwsFile

# Ensure $PROFILE exists and dot-sources pws-profile.ps1
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Force -Path $PROFILE | Out-Null }
$includeLine = ". '$pwsFile'"
$profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
if (-not ($profileContent -match ('(?m)^\s*\.\s+.*' + [regex]::Escape('pws-profile.ps1')))) {
    Add-Content -Path $PROFILE -Value "`n$includeLine"
}
```

This keeps your own `$PROFILE` intact and places the downloaded file alongside it as `pws-profile.ps1`.

Notes:
- The unified file is generated automatically by CI and committed to `dist/pws-profile.ps1` in the `main` branch.
- The CI also uploads the file as an artifact for each run, should you prefer downloading from the workflow run UI.

### Local build (optional)

If you want to generate the unified file locally:

```powershell
pwsh -NoProfile -File ./scripts/concat-pws.ps1
```

The output will be written to `dist/pws-profile.ps1`.

## Function Catalog (HTML)

For a quick overview of all available functions (sorted by name), see:

- [docs/functions.html](https://ignatandrei.github.io/powershellProfile/functions.html)

It is generated from all PowerShell scripts under `src` and includes:
- a short description for each function
- one usage example per function

Regenerate it after updating scripts:

```powershell
pwsh -NoProfile -File ./scripts/generate-functions-html.ps1
```

## UpdateMe

Once installed, use `updateMe` for all future updates. It downloads the latest `pws-profile.ps1` next to your `$PROFILE` (backing up the previous copy), then ensures your `$PROFILE` still dot-sources it.

```powershell
updateMe
```