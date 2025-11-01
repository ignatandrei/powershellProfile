# powershellProfile
A collection of utilities for PowerShell profile.

## Unified profile via CI

This repository contains multiple small `.ps1` utility files under `src/pws`. A GitHub Actions workflow concatenates them (alphabetically) into a single, ready-to-use profile script at `dist/pws-profile.ps1` on every push to `main` and also publishes it as a build artifact.

### Install/update into your PowerShell `$PROFILE`

Run this once (or any time you want to update) to download the latest generated profile into your `$PROFILE` path:

```powershell
# Ensure the profile directory exists, then download the latest unified profile
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Force -Path $profileDir | Out-Null }
Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/ignatandrei/powershellProfile/main/dist/pws-profile.ps1" -OutFile $PROFILE
```

Notes:
- The unified file is generated automatically by CI and committed to `dist/pws-profile.ps1` in the `main` branch.
- The CI also uploads the file as an artifact for each run, should you prefer downloading from the workflow run UI.

### Local build (optional)

If you want to generate the unified file locally:

```powershell
pwsh -NoProfile -File ./scripts/concat-pws.ps1
```

The output will be written to `dist/pws-profile.ps1`.
