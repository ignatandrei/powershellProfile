Param(
    [string]$SourceFolder = (Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'src'),
    [string]$OutFile = (Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'dist/pws-profile.ps1')
)

Write-Host "Source folder: $SourceFolder"
Write-Host "Output file  : $OutFile"

# Ensure output directory exists
$null = New-Item -ItemType Directory -Path (Split-Path -Parent $OutFile) -Force

# Resolve files to concatenate (alphabetical by name)
$files = Get-ChildItem -Path $SourceFolder -Filter '*.ps1' -File -Recurse | Sort-Object Name

if (-not $files) {
    Write-Error "No .ps1 files found in $SourceFolder"
    exit 1
}

$now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'
$repo = $env:GITHUB_REPOSITORY

$repoLine = if ($repo) { "# Repository: $repo" } else { '# Repository: (local run)' }

$header = @(
    '# ============================================================================'
    '# Unified PowerShell Profile'
    ("# Generated: $now")
    $repoLine
    '# Source folder: src/pws'
    '# Files concatenated in alphabetical order'
    '# ============================================================================'
    ''
)

$content = @()
$content += $header

foreach ($f in $files) {
    $name = $f.Name
    $content += "# >>> BEGIN: $name"
    $content += (Get-Content -LiteralPath $f.FullName -Raw)
    $content += "# <<< END: $name"
    $content += ''
}

# Write with UTF-8 encoding
$content | Set-Content -LiteralPath $OutFile -Encoding utf8

Write-Host "Wrote unified profile to: $OutFile"
