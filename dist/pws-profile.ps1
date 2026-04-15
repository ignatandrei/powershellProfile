# ============================================================================
# Unified PowerShell Profile
# Generated: 2026-04-15 16:50:57 +00:00
# Repository: ignatandrei/powershellProfile
# Source folder: src/pws
# Files concatenated in alphabetical order
# ============================================================================

# >>> BEGIN: Analysis.ps1
function Get-GitAnalysisRepositoryRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path
    )

    $repoRoot = git -C $Path rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
        Write-Error "Path '$Path' is not inside a Git repository."
        return $null
    }

    return $repoRoot.Trim()
}

function ConvertTo-GroupedFileCount {
    [CmdletBinding()]
    param(
        [string[]]$FilePaths,

        [Parameter(Mandatory = $false)]
        [int]$Top = 20
    )

    if (-not $FilePaths) {
        return @()
    }

    $FilePaths |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Group-Object |
        Sort-Object -Property Count, Name -Descending |
        Select-Object -First $Top |
        ForEach-Object {
            [pscustomobject]@{
                Count = $_.Count
                File  = $_.Name
            }
        }
}

function Get-GitChurnHotspots {
    <#
    .SYNOPSIS
        Lists the most frequently changed files in a Git repository.

    .DESCRIPTION
        PowerShell equivalent of:
        git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20

        Uses Group-Object instead of uniq -c to count how often each file appears in
        the Git history for the selected time window.

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .PARAMETER Since
        Git --since filter. Defaults to '1 year ago'.

    .PARAMETER Top
        Maximum number of files to return. Defaults to 20.

    .EXAMPLE
        Get-GitChurnHotspots

    .EXAMPLE
        Get-GitChurnHotspots -Since "6 months ago" -Top 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$Since = "1 year ago",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 500)]
        [int]$Top = 20
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    $gitArgs = @('-C', $repoRoot, 'log', '--format=format:', '--name-only')
    if (-not [string]::IsNullOrWhiteSpace($Since)) {
        $gitArgs += "--since=$Since"
    }

    $files = & git @gitArgs 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to read Git log for churn hotspots."
        return
    }

    ConvertTo-GroupedFileCount -FilePaths $files -Top $Top
}

function Get-GitContributorsByCommitCount {
    <#
    .SYNOPSIS
        Lists contributors ranked by non-merge commit count.

    .DESCRIPTION
        PowerShell equivalent of:
        git shortlog -sn --no-merges

        Returns parsed objects so the output can be formatted, filtered, or exported.

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .PARAMETER Since
        Optional Git --since filter, for example '6 months ago'.

    .EXAMPLE
        Get-GitContributorsByCommitCount

    .EXAMPLE
        Get-GitContributorsByCommitCount -Since "6 months ago"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$Since
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    $gitArgs = @('-C', $repoRoot, 'shortlog', '-sn', '--no-merges')
    if (-not [string]::IsNullOrWhiteSpace($Since)) {
        $gitArgs += "--since=$Since"
    }

    $lines = & git @gitArgs 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to read Git shortlog."
        return
    }

    foreach ($line in $lines) {
        if ($line -match '^\s*(?<Count>\d+)\s+(?<Author>.+)$') {
            [pscustomobject]@{
                CommitCount = [int]$Matches['Count']
                Author      = $Matches['Author'].Trim()
            }
        }
    }
}

function Get-GitBugHotspots {
    <#
    .SYNOPSIS
        Lists files most frequently touched by bug-fix commits.

    .DESCRIPTION
        PowerShell equivalent of:
        git log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -20

        Uses Git commit message filtering plus Group-Object to replace uniq -c.

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .PARAMETER Pattern
        Regex used with git log --grep. Defaults to 'fix|bug|broken'.

    .PARAMETER Top
        Maximum number of files to return. Defaults to 20.

    .EXAMPLE
        Get-GitBugHotspots

    .EXAMPLE
        Get-GitBugHotspots -Pattern "fix|bug|broken|defect" -Top 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$Pattern = 'fix|bug|broken',

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 500)]
        [int]$Top = 20
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    $gitArgs = @('-C', $repoRoot, 'log', '-i', '-E', "--grep=$Pattern", '--name-only', '--format=format:')
    $files = & git @gitArgs 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to read Git log for bug hotspots."
        return
    }

    ConvertTo-GroupedFileCount -FilePaths $files -Top $Top
}

function Get-GitCommitVelocityByMonth {
    <#
    .SYNOPSIS
        Shows commit counts grouped by month.

    .DESCRIPTION
        PowerShell equivalent of:
        git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c

        Uses Group-Object to count commits per month.

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .EXAMPLE
        Get-GitCommitVelocityByMonth
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    $months = & git -C $repoRoot log '--format=%ad' '--date=format:%Y-%m' 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to read Git log for monthly commit velocity."
        return
    }

    $months |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Group-Object |
        Sort-Object -Property Name |
        ForEach-Object {
            [pscustomobject]@{
                Month       = $_.Name
                CommitCount = $_.Count
            }
        }
}

function Get-GitFirefightingCommits {
    <#
    .SYNOPSIS
        Lists likely firefighting commits such as hotfixes or rollbacks.

    .DESCRIPTION
        PowerShell equivalent of:
        git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'

        This version uses git log --grep so it works natively in PowerShell.

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .PARAMETER Since
        Git --since filter. Defaults to '1 year ago'.

    .PARAMETER Pattern
        Regex used with git log --grep. Defaults to 'revert|hotfix|emergency|rollback'.

    .EXAMPLE
        Get-GitFirefightingCommits

    .EXAMPLE
        Get-GitFirefightingCommits -Since "6 months ago"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$Since = "1 year ago",

        [Parameter(Mandatory = $false)]
        [string]$Pattern = 'revert|hotfix|emergency|rollback'
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    $gitArgs = @('-C', $repoRoot, 'log', '--oneline', '-i', '-E', "--grep=$Pattern")
    if (-not [string]::IsNullOrWhiteSpace($Since)) {
        $gitArgs += "--since=$Since"
    }

    $lines = & git @gitArgs 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to read Git log for firefighting commits."
        return
    }

    foreach ($line in $lines) {
        if ($line -match '^(?<Commit>[0-9a-f]+)\s+(?<Message>.+)$') {
            [pscustomobject]@{
                Commit  = $Matches['Commit']
                Message = $Matches['Message']
            }
        }
    }
}

function Invoke-GitRepositoryAnalysis {
    <#
    .SYNOPSIS
        Runs the five Git diagnostics from issue #13 in PowerShell.

    .DESCRIPTION
        Translates the commands from
        https://piechowski.io/post/git-commands-before-reading-code/
        into native PowerShell-friendly helpers.

        The main differences are:
        - Group-Object replaces uniq -c
        - git log --grep replaces grep-based filtering where practical

        The command prints five sections:
        - churn hotspots
        - contributor ranking
        - bug hotspots
        - monthly commit velocity
        - firefighting commits

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .PARAMETER Since
        Shared Git --since filter for churn and firefighting views. Defaults to '1 year ago'.

    .PARAMETER Top
        Number of rows shown for hotspot sections. Defaults to 20.

    .EXAMPLE
        Invoke-GitRepositoryAnalysis

    .EXAMPLE
        analysis -Since "6 months ago" -Top 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$Since = "1 year ago",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 500)]
        [int]$Top = 20
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    Write-Host ""
    Write-Host "Git repository analysis: $repoRoot" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "=== What Changes the Most ===" -ForegroundColor Yellow
    $churn = @(Get-GitChurnHotspots -Path $repoRoot -Since $Since -Top $Top)
    if ($churn.Count -gt 0) {
        $churn | Format-Table -AutoSize | Out-Host
    }
    else {
        Write-Host "No churn data found." -ForegroundColor DarkYellow
    }
    Write-Host ""

    Write-Host "=== Who Built This ===" -ForegroundColor Yellow
    $contributors = @(Get-GitContributorsByCommitCount -Path $repoRoot)
    if ($contributors.Count -gt 0) {
        $contributors | Format-Table -AutoSize | Out-Host
    }
    else {
        Write-Host "No contributor data found." -ForegroundColor DarkYellow
    }
    Write-Host ""

    Write-Host "=== Where Do Bugs Cluster ===" -ForegroundColor Yellow
    $bugHotspots = @(Get-GitBugHotspots -Path $repoRoot -Top $Top)
    if ($bugHotspots.Count -gt 0) {
        $bugHotspots | Format-Table -AutoSize | Out-Host
    }
    else {
        Write-Host "No bug hotspot data found." -ForegroundColor DarkYellow
    }
    Write-Host ""

    Write-Host "=== Is This Project Accelerating or Dying ===" -ForegroundColor Yellow
    $velocity = @(Get-GitCommitVelocityByMonth -Path $repoRoot)
    if ($velocity.Count -gt 0) {
        $velocity | Format-Table -AutoSize | Out-Host
    }
    else {
        Write-Host "No commit velocity data found." -ForegroundColor DarkYellow
    }
    Write-Host ""

    Write-Host "=== How Often Is the Team Firefighting ===" -ForegroundColor Yellow
    $firefighting = @(Get-GitFirefightingCommits -Path $repoRoot -Since $Since)
    if ($firefighting.Count -gt 0) {
        $firefighting | Format-Table -AutoSize | Out-Host
    }
    else {
        Write-Host "No firefighting commits found." -ForegroundColor DarkYellow
    }
}

Set-Alias -Name analysis -Value Invoke-GitRepositoryAnalysis

#usage Get-GitChurnHotspots
#usage Get-GitContributorsByCommitCount
#usage Get-GitBugHotspots
#usage Get-GitCommitVelocityByMonth
#usage Get-GitFirefightingCommits
#usage Invoke-GitRepositoryAnalysis
#usage analysis

# <<< END: Analysis.ps1

# >>> BEGIN: audioVideoPictures.ps1
function Convert-VideoToH264 {
    <#
    .SYNOPSIS
        Converts a video file to H.264 format using ffmpeg.
    
    .DESCRIPTION
        Uses ffmpeg to convert video files to H.264 format with optimized settings for web playback.
        Includes fast start for streaming and configurable quality settings.
    
    .PARAMETER InputFile
        The path to the input video file to convert.
    
    .PARAMETER OutputFile
        The path where the converted video file will be saved.
    
    .PARAMETER CRF
        Constant Rate Factor for quality control (0-51, lower is better quality).
        Default is 30. Typical values: 18-28 for good quality, 30+ for smaller files.
    
    .EXAMPLE
        Convert-VideoToH264 -InputFile "input.mp4" -OutputFile "output.mp4"
        Converts input.mp4 to output.mp4 with default quality (CRF 30).
    
    .EXAMPLE
        Convert-VideoToH264 -InputFile "video.avi" -OutputFile "video_h264.mp4" -CRF 23
        Converts video.avi to video_h264.mp4 with higher quality (CRF 23).
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$InputFile,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$OutputFile,
        
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateRange(0, 51)]
        [int]$CRF = 30
    )
    
    # Check if ffmpeg is available
    try {
        $null = Get-Command ffmpeg -ErrorAction Stop
    }
    catch {
        Write-Error "ffmpeg is not installed or not in PATH. Please install ffmpeg first."
        return
    }
    
    # Build and execute the ffmpeg command
    $ffmpegArgs = @(
        '-i', $InputFile,
        '-c:v', 'libx264',
        '-tag:v', 'avc1',
        '-movflags', 'faststart',
        '-crf', $CRF.ToString(),
        '-preset', 'superfast',
        $OutputFile
    )
    
    Write-Host "Converting video: $InputFile -> $OutputFile (CRF: $CRF)" -ForegroundColor Cyan
    
    & ffmpeg @ffmpegArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Conversion completed successfully!" -ForegroundColor Green
    }
    else {
        Write-Error "ffmpeg conversion failed with exit code: $LASTEXITCODE"
    }
}

Set-Alias shrinkvid Convert-VideoToH264

function Convert-VideoToHighQualityMP4 {
    <#
    .SYNOPSIS
        Converts a video file to high-quality H.264 MP4 format using ffmpeg.
    
    .DESCRIPTION
        Uses ffmpeg to convert video files to H.264 MP4 format with very high quality settings.
        Uses CRF 18 (high quality) and veryslow preset for maximum compression efficiency.
        Copies the audio stream without re-encoding.
    
    .PARAMETER InputFile
        The path to the input video file to convert.
    
    .EXAMPLE
        Convert-VideoToHighQualityMP4 -InputFile "video.avi"
        Converts video.avi to video.avi.mp4 with high quality settings.
    
    .EXAMPLE
        Convert-VideoToHighQualityMP4 "input.mkv"
        Converts input.mkv to input.mkv.mp4 with high quality settings.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$InputFile
    )
    
    # Check if ffmpeg is available
    try {
        $null = Get-Command ffmpeg -ErrorAction Stop
    }
    catch {
        Write-Error "ffmpeg is not installed or not in PATH. Please install ffmpeg first."
        return
    }
    
    # Output file will be input file name + .mp4
    $OutputFile = "$InputFile.mp4"
    
    # Build and execute the ffmpeg command
    $ffmpegArgs = @(
        '-i', $InputFile,
        '-c:v', 'libx264',
        '-crf', '18',
        '-preset', 'veryslow',
        '-c:a', 'copy',
        $OutputFile
    )
    
    Write-Host "Converting video to high-quality MP4: $InputFile -> $OutputFile" -ForegroundColor Cyan
    Write-Host "Settings: CRF 18, Preset: veryslow (this will take a while)" -ForegroundColor Yellow
    
    & ffmpeg @ffmpegArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Conversion completed successfully!" -ForegroundColor Green
    }
    else {
        Write-Error "ffmpeg conversion failed with exit code: $LASTEXITCODE"
    }
}

function Convert-VideoToGif {
    <#
    .SYNOPSIS
        Converts a video file to an animated GIF using ffmpeg.
    
    .DESCRIPTION
        Uses ffmpeg to convert video files (or MP4 files) to animated GIF format.
        Optimized settings: 12 fps, 900px width, and lanczos scaling for quality.
    
    .PARAMETER InputFile
        The path to the input video file to convert. Can be any video format or MP4.
    
    .EXAMPLE
        Convert-VideoToGif -InputFile "video.avi"
        Converts video.avi to video.avi.gif.
    
    .EXAMPLE
        Convert-VideoToGif "video.mp4"
        Converts video.mp4 to video.mp4.gif.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$InputFile
    )
    
    # Check if ffmpeg is available
    try {
        $null = Get-Command ffmpeg -ErrorAction Stop
    }
    catch {
        Write-Error "ffmpeg is not installed or not in PATH. Please install ffmpeg first."
        return
    }
    
    # Determine if input already has .mp4 extension
    $mp4File = if ($InputFile -match '\.mp4$') {
        $InputFile
    } else {
        "$InputFile.mp4"
    }
    
    # Output file will be input file name + .gif
    $OutputFile = "$InputFile.gif"
    
    # Check if we need to use the MP4 version
    if (-not (Test-Path $mp4File)) {
        Write-Error "MP4 file not found: $mp4File. Please ensure the MP4 file exists."
        return
    }
    
    # Build and execute the ffmpeg command
    $ffmpegArgs = @(
        '-i', $mp4File,
        '-vf', 'fps=12,scale=900:-1:flags=lanczos',
        '-loop', '0',
        $OutputFile
    )
    
    Write-Host "Converting video to GIF: $mp4File -> $OutputFile" -ForegroundColor Cyan
    Write-Host "Settings: 12 fps, 900px width, lanczos scaling" -ForegroundColor Yellow
    
    & ffmpeg @ffmpegArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "GIF conversion completed successfully!" -ForegroundColor Green
    }
    else {
        Write-Error "ffmpeg conversion failed with exit code: $LASTEXITCODE"
    }
}

function Convert-VideoToMP4AndGif {
    <#
    .SYNOPSIS
        Converts a video file to both high-quality MP4 and animated GIF.
    
    .DESCRIPTION
        Combines Convert-VideoToHighQualityMP4 and Convert-VideoToGif into a single command.
        First converts the input video to high-quality MP4, then creates an animated GIF from it.
    
    .PARAMETER InputFile
        The path to the input video file to convert.
    
    .EXAMPLE
        Convert-VideoToMP4AndGif -InputFile "video.avi"
        Creates both video.avi.mp4 and video.avi.gif.
    
    .EXAMPLE
        Convert-VideoToMP4AndGif "input.mkv"
        Creates both input.mkv.mp4 and input.mkv.gif.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$InputFile
    )
    
    Write-Host "`n=== Starting Video Conversion Pipeline ===" -ForegroundColor Magenta
    Write-Host "Input: $InputFile`n" -ForegroundColor Magenta
    
    # Step 1: Convert to high-quality MP4
    Write-Host "[Step 1/2] Converting to high-quality MP4..." -ForegroundColor Cyan
    Convert-VideoToHighQualityMP4 -InputFile $InputFile
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "MP4 conversion failed. Aborting GIF conversion."
        return
    }
    
    Write-Host "`n" # Add spacing
    
    # Step 2: Convert to GIF
    Write-Host "[Step 2/2] Converting to animated GIF..." -ForegroundColor Cyan
    Convert-VideoToGif -InputFile $InputFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n=== Conversion Pipeline Completed Successfully ===" -ForegroundColor Magenta
        Write-Host "Output files:" -ForegroundColor Green
        Write-Host "  - $InputFile.mp4" -ForegroundColor Green
        Write-Host "  - $InputFile.gif" -ForegroundColor Green
    }
    else {
        Write-Warning "MP4 conversion succeeded, but GIF conversion failed."
    }
}

Set-Alias vidconvert Convert-VideoToMP4AndGif

# <<< END: audioVideoPictures.ps1

# >>> BEGIN: clipboard.ps1
# do not see the need for pastas

function copyCommand {
  <#
  .SYNOPSIS
  Copies incoming text to the Windows clipboard.

  .DESCRIPTION
  Accepts text from the pipeline (each object is stringified) or as direct arguments.
  Joins multiple lines with the system newline and trims the trailing newline.

  .EXAMPLE
  'npm run start' | copyCommand
  Copies the literal string to the clipboard.

  .EXAMPLE
  copyCommand npm run start
  Copies "npm run start" to the clipboard (arguments are joined by spaces).

  .EXAMPLE
  npm --version | copyCommand
  Copies the output of the command into the clipboard.
  #>
  [CmdletBinding()]
  param(
    # Accept pipeline input only; not positional to avoid stealing first arg
    [Parameter(ValueFromPipeline = $true)]
    [AllowNull()]
    $InputObject,

    # When not using the pipeline, you can pass the command words as arguments
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$CommandParts
  )

  begin {
    $lines = New-Object System.Collections.Generic.List[string]
    $receivedFromPipeline = $false
  }

  process {
    # If input is actually coming via the pipeline, ExpectingInput is true
    if ($PSCmdlet.MyInvocation.ExpectingInput) { $receivedFromPipeline = $true }
    if ($null -ne $InputObject) { $lines.Add([string]$InputObject) }
  }

  end {
    # If nothing came from the pipeline, but arguments were given, use them
    if (-not $receivedFromPipeline -and $CommandParts -and $CommandParts.Count -gt 0) {
        $first = $CommandParts[0]
        if (Test-Path $first -PathType Leaf){
            $content =Get-Content $first
            $lines.AddRange($content)
        }
    else{

            $lines.Add([string]::Join(' ', $CommandParts))
        }
    }

    $text = ($lines -join [Environment]::NewLine).TrimEnd("`r","`n")

    if (-not [string]::IsNullOrWhiteSpace($text)) {
      try {
        $null = Set-Clipboard -Value $text
        Write-Host "Copied to clipboard ($($text.Length) chars)" -ForegroundColor Green
      }
      catch {
        Write-Warning "Failed to copy to clipboard: $($_.Exception.Message)"
      }

      # Return the text to allow further piping if desired
      $text
    }
    else {
      Write-Warning "No input to copy. Pipe text or pass args, e.g.: 'npm run start' | copyCommand or: copyCommand npm run start"
    }
    # Write-Host $CommandParts.Count
  }
}

# Short alias
Set-Alias ccopy copyCommand
#usage ccopy npm --version
#usage ccopy path\to\file.txt 
#usage 'npm --version' | ccopy
#usage  npm --version | copyCommand 

function CopyCurDir(){
    <#
    .SYNOPSIS
    Copies the current directory path to the Windows clipboard.

    .DESCRIPTION
    Retrieves the current working directory and writes its full path to the clipboard,
    then prints a confirmation message.

    .EXAMPLE
    CopyCurDir
    Copies the current directory path to the clipboard.

    .EXAMPLE
    ccd
    Uses the alias to copy the current directory path.
    #>
    $currentDir = Get-Location
    $null = Set-Clipboard -Value $currentDir.Path
    Write-Host "Copied current directory to clipboard: $($currentDir.Path)" -ForegroundColor Green
}
Set-Alias ccd CopyCurDir
Set-Alias cpwd CopyCurDir
#usage ccd
#usage cpwd


# <<< END: clipboard.ps1

# >>> BEGIN: copilot.ps1
function Install-Psmux {
	<#
	.SYNOPSIS
		Installs psmux via winget

	.DESCRIPTION
		Runs 'winget install psmux' to install the psmux terminal multiplexer.

	.EXAMPLE
		Install-Psmux

	.EXAMPLE
		psmux-install
	#>
	[CmdletBinding()]
	param()

	Write-Host "Installing psmux via winget..." -ForegroundColor Cyan
	winget install psmux
}

Set-Alias -Name psmux-install -Value Install-Psmux

#usage Install-Psmux
#usage psmux-install

function Install-Squad {
	<#
	.SYNOPSIS
		Installs the Squad CLI via npm

	.DESCRIPTION
		Runs 'npm i -g @bradygaster/squad-cli' to install the Squad CLI tool globally.

	.EXAMPLE
		Install-Squad

	.EXAMPLE
		squad-install
	#>
	[CmdletBinding()]
	param()

	Write-Host "Installing Squad CLI via npm..." -ForegroundColor Cyan
	npm i -g @bradygaster/squad-cli
}

Set-Alias -Name squad-install -Value Install-Squad

#usage Install-Squad
#usage squad-install

function Install-Sbx {
	<#
	.SYNOPSIS
		Installs Docker sbx via winget

	.DESCRIPTION
		Runs 'winget install -h Docker.sbx' to silently install Docker sbx.
		Also prints a reminder to enable the HypervisorPlatform Windows feature if needed.

	.EXAMPLE
		Install-Sbx

	.EXAMPLE
		sbx-install
	#>
	[CmdletBinding()]
	param()

	Write-Host "Installing sbx via winget..." -ForegroundColor Cyan
	winget install -h Docker.sbx
    Write-Host "You may need to enable the Hypervisor Platform feature..." -ForegroundColor Cyan
    Write-Host "Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All"

}

Set-Alias -Name sbx-install -Value Install-Sbx

#usage Install-Sbx
#usage sbx-install

function Get-CurrentGitUrl {
	<#
	.SYNOPSIS
		Returns the remote URL of the current Git repository

	.DESCRIPTION
		Resolves the repository root from the given path and returns the URL
		of the specified remote (default: origin).

	.PARAMETER Path
		Path inside the Git repository. Defaults to the current directory.

	.PARAMETER Remote
		Name of the remote to query. Defaults to 'origin'.

	.EXAMPLE
		Get-CurrentGitUrl

	.EXAMPLE
		giturl

	.EXAMPLE
		Get-CurrentGitUrl -Remote upstream
	#>
	[CmdletBinding()]
	param(
		[string]$Path = (Get-Location).Path,
		[string]$Remote = "origin"
	)

	$repoRoot = git -C $Path rev-parse --show-toplevel 2>$null
	if (-not $repoRoot) {
		Write-Warning "Path is not inside a Git repository."
		return
	}

	$url = git -C $repoRoot config --get ("remote.{0}.url" -f $Remote) 2>$null
	if (-not $url) {
		Write-Warning ("Remote '{0}' not found." -f $Remote)
		return
	}

	$url
}

Set-Alias -Name giturl -Value Get-CurrentGitUrl

#usage Get-CurrentGitUrl
#usage giturl
#usage Get-CurrentGitUrl -Remote upstream

function Get-CurrentGitName {
	<#
	.SYNOPSIS
		Returns the name of the current Git repository

	.DESCRIPTION
		Resolves the repository root from the given path and returns the
		folder name that represents the repository name.

	.PARAMETER Path
		Path inside the Git repository. Defaults to the current directory.

	.EXAMPLE
		Get-CurrentGitName

	.EXAMPLE
		gitname
	#>
	[CmdletBinding()]
	param(
		[string]$Path = (Get-Location).Path
	)

	$repoRoot = git -C $Path rev-parse --show-toplevel 2>$null
	if (-not $repoRoot) {
		Write-Warning "Path is not inside a Git repository."
		return
	}

	Split-Path -Path $repoRoot -Leaf
}

Set-Alias -Name gitname -Value Get-CurrentGitName

#usage Get-CurrentGitName
#usage gitname

function New-BranchWorkspace {
	<#
	.SYNOPSIS
		Clones the current Git repo into a new branch-specific workspace folder

	.DESCRIPTION
		Goes one level above the current directory, creates a folder named
		'[repoName]_[branchName]', clones the current remote into it, then
		checks out the specified branch (creating it if it does not exist on
		the remote). Finally echoes 'sbx run copilot'.

	.PARAMETER BranchName
		The name of the branch to check out or create inside the new workspace.

	.EXAMPLE
		New-BranchWorkspace myFeature

	.EXAMPLE
		branchws myFeature
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string]$BranchName
	)

	# Resolve current repo URL and name
	$gitUrl = Get-CurrentGitUrl
	if (-not $gitUrl) { return }

	$gitRepoName = Get-CurrentGitName
	if (-not $gitRepoName) { return }

	# Build target folder one level above the current directory
	$parentFolder = Split-Path -Path (Get-Location).Path -Parent
	$invalidFileNameChars = [System.IO.Path]::GetInvalidFileNameChars() + [char[]]('/\')
	$escapedInvalidFileNameChars = [regex]::Escape((-join $invalidFileNameChars))
	$safeBranchName = $BranchName -replace "[{0}]" -f $escapedInvalidFileNameChars, "_"
	$targetFolder = Join-Path $parentFolder ("{0}_{1}" -f $gitRepoName, $safeBranchName)

	Write-Host "Creating workspace folder: $targetFolder" -ForegroundColor Cyan
	New-Item -ItemType Directory -Force -Path $targetFolder | Out-Null

	# Clone the repository into the new folder
	Write-Host "Cloning $gitUrl into $targetFolder ..." -ForegroundColor Cyan
	git clone $gitUrl $targetFolder

	if ($LASTEXITCODE -ne 0) {
		Write-Error "git clone failed."
		return
	}

	# Check whether the branch already exists on the remote
	$remoteBranch = git -C $targetFolder ls-remote --heads origin $BranchName 2>$null
	if ($remoteBranch) {
		Write-Host "Branch '$BranchName' exists on remote. Checking out..." -ForegroundColor Green
		git -C $targetFolder checkout $BranchName
	}
	else {
		Write-Host "Branch '$BranchName' does not exist. Creating..." -ForegroundColor Yellow
		git -C $targetFolder checkout -b $BranchName
	}

	Write-Host "Launching github desktop in the new workspace..." -ForegroundColor Cyan
	Start-Process "github" -ArgumentList $targetFolder
	Write-Host "tmux new -s $BranchName" -ForegroundColor Cyan
	Write-Host "sbx run copilot"

	Set-Location $targetFolder

}

Set-Alias -Name branchws -Value New-BranchWorkspace

#usage New-BranchWorkspace myFeature
#usage branchws myFeature









# <<< END: copilot.ps1

# >>> BEGIN: datesAndTimes.ps1
function GetISoDate {
    <#
    .SYNOPSIS
    Returns the current date in ISO 8601 format (yyyy-MM-dd).

    .EXAMPLE
    GetISoDate
    Returns today's date, for example: 2025-04-15
    #>
    # Returns the current date and time in ISO 8601 format
    return (Get-Date).ToString("yyyy-MM-dd")
}
function GetISoDateTime {
    <#
    .SYNOPSIS
    Returns the current date and time in ISO 8601 compact format (yyyyMMddTHHmmss).

    .EXAMPLE
    GetISoDateTime
    Returns the current timestamp, for example: 20250415T103045
    #>
    # Returns the current date and time in ISO 8601 format
    return (Get-Date).ToString("yyyyMMddTHHmmss")
}
function IsoDateTimeAsVersion {
    <#
    .SYNOPSIS
    Returns the current date and time as a four-part version number (1.yyyy.MMdd.HHmm).

    .EXAMPLE
    IsoDateTimeAsVersion
    Returns a version string, for example: 1.2025.0415.1030
    #>
    # Returns the current date and time in ISO 8601 format
    return (Get-Date).ToString("1.yyyy.MMdd.HHmm")
}
Set-Alias hoy GetISoDate
Set-Alias hoyt GetISoDateTime
Set-Alias hoyv IsoDateTimeAsVersion

function Start-MinuteTimer {
    <#
    .SYNOPSIS
        Starts a simple countdown timer for the specified number of minutes.

    .DESCRIPTION
        Prints a message every minute indicating how many minutes remain.
        When the countdown reaches zero, prints "Time's up!".

        Example:
            Start-MinuteTimer -Minutes 3
            # Output:
            # 3 minutes left...
            # 2 minutes left...
            # 1 minute left...
            # Time's up!

    .PARAMETER Minutes
        The number of minutes to run the timer. 0 will complete immediately.

    .NOTES
        Press Ctrl+C to interrupt the timer early.
        Use -PlaySound to play a brief sound each minute and at completion.
        Use -Notify to show a Windows balloon notification at completion.

    .EXAMPLE
        Start-MinuteTimer -Minutes 5
        Starts a 5-minute countdown, printing the remaining minutes each minute.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Minutes

         )

    if ($Minutes -le 0) {
        Write-Host "Time's up!"
        return
    }
    try { 
        Show-BalloonNotification -Title "Waiting" -Message "Waiting for $Minutes minute(s) to elapse." } catch {
         Write-Verbose "Notification failed: $_" 
        }

    $completed = $true
    for ($remaining = $Minutes; $remaining -gt 0; $remaining--) {
        $unit = if ($remaining -eq 1) { 'minute' } else { 'minutes' }
        Write-Host ("{0} {1} left..." -f $remaining, $unit)
            try { [System.Media.SystemSounds]::Asterisk.Play() } catch { }
        
        try {
            Start-Sleep -Seconds 60
        }
        catch {
            $completed = $false
            Write-Warning "Timer interrupted."
            break
        }
    }

    if ($completed) {
        Write-Host "Time's up!"
            try { [System.Media.SystemSounds]::Exclamation.Play() } catch { }
            try { Show-BalloonNotification -Title "Timer finished" -Message ("{0}-minute timer completed." -f $Minutes) } catch { Write-Verbose "Notification failed: $_" }
        
    }
    else {
        Write-Host ("Timer cancelled with {0} minute{1} left." -f $remaining, $(if ($remaining -eq 1) { '' } else { 's' }))
        try { Show-BalloonNotification -Title "Timer cancelled" -Message ("Cancelled with {0} minute{1} left." -f $remaining, $(if ($remaining -eq 1) { '' } else { 's' })) } catch { Write-Verbose "Notification failed: $_" }
        
    }
}

function Show-BalloonNotification {
    <#
    .SYNOPSIS
    Displays a Windows system tray balloon notification.

    .DESCRIPTION
    Uses System.Windows.Forms.NotifyIcon to show a balloon tip in the Windows
    notification area. The notification disappears after the specified timeout.

    .PARAMETER Title
    The title text shown at the top of the balloon notification.

    .PARAMETER Message
    The body text of the balloon notification.

    .PARAMETER TimeoutMilliseconds
    How long (in milliseconds) the balloon stays visible. Default is 5000 ms.

    .EXAMPLE
    Show-BalloonNotification -Title "Done" -Message "Build completed successfully!"
    Shows a balloon notification with the given title and message for 5 seconds.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Title,
        [Parameter(Mandatory, Position = 1)]
        [string]$Message,
        [int]$TimeoutMilliseconds = 5000
    )

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    }
    catch {
        throw "Unable to load Windows Forms assemblies for notification: $_"
    }

    $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
    $notifyIcon.BalloonTipTitle = $Title
    $notifyIcon.BalloonTipText = $Message
    $notifyIcon.Visible = $true
    $notifyIcon.ShowBalloonTip($TimeoutMilliseconds)

    Start-Sleep -Milliseconds ($TimeoutMilliseconds + 500)
    $notifyIcon.Dispose()
}

set-Alias timer Start-MinuteTimer

function Show-MonthCalendar {
    <#
    .SYNOPSIS
        Prints a text calendar for a month.

    .DESCRIPTION
        By default prints the current month. You can optionally specify -Year and -Month,
        choose to start the week on Monday, and highlight today's date.

    .PARAMETER Year
        The year of the month to display. Defaults to the current year.

    .PARAMETER Month
        The month (1-12) to display. Defaults to the current month.

    .PARAMETER StartOnMonday
        If set, the week will start on Monday (Mo..Su). Otherwise it starts on Sunday (Su..Sa).

    .PARAMETER HighlightToday
        If set and the displayed month includes today, highlights today's date.

    .EXAMPLE
        Show-MonthCalendar
        # Shows the current month.

    .EXAMPLE
        Show-MonthCalendar -Year 2025 -Month 11 -StartOnMonday -HighlightToday
    #>
    [CmdletBinding()]
    param(
        [int]$Year = (Get-Date).Year,
        [ValidateRange(1,12)]
        [int]$Month = (Get-Date).Month,
        [switch]$StartOnMonday
    )

    $HighlightToday = $true
    $firstDay = Get-Date -Year $Year -Month $Month -Day 1 -Hour 0 -Minute 0 -Second 0
    $daysInMonth = [DateTime]::DaysInMonth($Year, $Month)
    #$monthName = $firstDay.ToString('MMMM yyyy')
    $today = Get-Date

    # Weekday header
    $weekDays = if ($StartOnMonday) { @('Mo','Tu','We','Th','Fr','Sa','Su') } else { @('Su','Mo','Tu','We','Th','Fr','Sa') }
    Write-Host ""
    Write-Host $today.ToString('d MMMM yyyy')
    Write-Host ($weekDays -join ' ')

    # Offset for first day
    $offset = [int]$firstDay.DayOfWeek  # Sunday=0 ... Saturday=6
    if ($StartOnMonday) { $offset = ($offset + 6) % 7 } # Monday=0 ... Sunday=6

    $currentDay = 1
    $isFirstRow = $true
    while ($currentDay -le $daysInMonth) {
        for ($col = 0; $col -lt 7; $col++) {
            if ($isFirstRow -and $col -lt $offset) {
                # Leading empty cells
                Write-Host -NoNewline "   "
            }
            elseif ($currentDay -le $daysInMonth) {
                $text = ('{0,2} ' -f $currentDay)
                $isToday = $HighlightToday -and ($Year -eq $today.Year) -and ($Month -eq $today.Month) -and ($currentDay -eq $today.Day)
                if ($isToday) {
                    Write-Host -NoNewline $text -ForegroundColor Yellow
                }
                else {
                    Write-Host -NoNewline $text
                }
                $currentDay++
            }
            else {
                # Trailing empty cells after the last day
                Write-Host -NoNewline "   "
            }
        }
        Write-Host
        $isFirstRow = $false
    }
}

Set-Alias cal Show-MonthCalendar
Set-Alias rn Show-MonthCalendar
# <<< END: datesAndTimes.ps1

# >>> BEGIN: file.ps1
# no need for trash or mksh
function MakeDirCD {
  <#
  .SYNOPSIS
  Creates a directory and changes the current location to it.

  .DESCRIPTION
  Creates the specified directory if it does not already exist, then sets
  the current working directory to that path.

  .PARAMETER Path
  The path of the directory to create and navigate to.

  .EXAMPLE
  MakeDirCD -Path "MyNewFolder"
  Creates MyNewFolder in the current directory and navigates into it.

  .EXAMPLE
  mkcd src
  Uses the alias to create and navigate to the src directory.
  #>
  param (
      [Parameter(Mandatory = $true)]
      [string]$Path
  )

  # Create the directory if it doesn't exist
  if (-not (Test-Path -Path $Path)) {
      New-Item -ItemType Directory -Path $Path | Out-Null
  }

  # Change to the newly created directory
  Set-Location -Path $Path
}

Set-Alias mkcd MakeDirCD
# usage mkcd Andrei

function Invoke-FsutilCommand {
    <#
    .SYNOPSIS
    Executes fsutil.exe with the given arguments, using sudo when not running as Administrator.

    .DESCRIPTION
    Internal helper that wraps fsutil.exe calls and automatically prepends sudo.exe
    when the current session is not elevated, so that callers do not need to handle
    privilege escalation themselves.

    .PARAMETER Arguments
    The argument list to pass directly to fsutil.exe (e.g. 'file', 'queryCaseSensitiveInfo', 'C:\Folder').

    .EXAMPLE
    Invoke-FsutilCommand -Arguments @('file', 'queryCaseSensitiveInfo', 'C:\MyFolder')
    Queries case-sensitivity info for C:\MyFolder via fsutil.exe.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    try {
        $fsutil = Get-Command -Name 'fsutil.exe' -CommandType Application -ErrorAction Stop
    }
    catch {
        Write-Error "fsutil.exe is required to query folder case sensitivity."
        return $null
    }

    $command = @($fsutil.Source) + $Arguments
    if (-not $isElevated) {
        $sudo = Get-Command -Name 'sudo.exe' -CommandType Application -ErrorAction Ignore
        if ($null -eq $sudo) {
            Write-Error "sudo.exe is required to run fsutil when the current PowerShell session is not elevated."
            return $null
        }

        $command = @($sudo.Source) + $command
    }

    $output = $null
    $exitCode = $null

    try {
        $output = & $command[0] $command[1..($command.Length - 1)] 2>&1
        $exitCode = $LASTEXITCODE
    }
    catch {
        Write-Error $_
        return $null
    }

    [PSCustomObject]@{
        Output = $output
        ExitCode = $exitCode
    }
}

function Get-FolderCaseSensitive {
    <#
    .SYNOPSIS
    Queries the case-sensitivity setting of a directory.

    .DESCRIPTION
    Uses fsutil.exe to report whether case sensitivity is enabled or disabled
    for the specified directory (Windows 10 1803+ feature).

    .PARAMETER Path
    The directory path to query. Defaults to the current directory.

    .EXAMPLE
    Get-FolderCaseSensitive
    Checks case sensitivity for the current directory.

    .EXAMPLE
    Get-FolderCaseSensitive -Path "C:\MyFolder"
    Checks case sensitivity for C:\MyFolder.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Error "Path '$Path' does not exist or is not a directory."
        return
    }

    $result = Invoke-FsutilCommand -Arguments @('file', 'queryCaseSensitiveInfo', $Path)
    if ($null -eq $result) {
        return
    }

    if ($result.ExitCode -ne 0) {
        Write-Error "fsutil failed for '$Path': $($result.Output)"
        return
    }

    Write-Output $result.Output
}

Set-Alias casestatus Get-FolderCaseSensitive
# Usage: casestatus
# Usage: casestatus -Path "C:\MyFolder"

function Enable-FolderCaseSensitive {
    <#
    .SYNOPSIS
    Enables case sensitivity for a directory.

    .DESCRIPTION
    Uses fsutil.exe to enable per-directory case sensitivity on Windows 10 1803+.
    New files and subdirectories created inside the folder will be treated as
    case-sensitive. Requires elevated (Administrator) privileges.

    .PARAMETER Path
    The directory path to modify. Defaults to the current directory.

    .EXAMPLE
    Enable-FolderCaseSensitive
    Enables case sensitivity for the current directory.

    .EXAMPLE
    Enable-FolderCaseSensitive -Path "C:\MyFolder"
    Enables case sensitivity for C:\MyFolder.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Error "Path '$Path' does not exist or is not a directory."
        return
    }

    $result = Invoke-FsutilCommand -Arguments @('file', 'setCaseSensitiveInfo', $Path, 'enable')
    if ($null -eq $result) {
        return
    }

    if ($result.ExitCode -ne 0) {
        Write-Error "fsutil failed for '$Path': $($result.Output)"
        return
    }

    Write-Output $result.Output
}

Set-Alias caseon Enable-FolderCaseSensitive
# Usage: caseon
# Usage: caseon -Path "C:\MyFolder"

function Disable-FolderCaseSensitive {
    <#
    .SYNOPSIS
    Disables case sensitivity for a directory.

    .DESCRIPTION
    Uses fsutil.exe to disable per-directory case sensitivity on Windows 10 1803+.
    Requires elevated (Administrator) privileges.

    .PARAMETER Path
    The directory path to modify. Defaults to the current directory.

    .EXAMPLE
    Disable-FolderCaseSensitive
    Disables case sensitivity for the current directory.

    .EXAMPLE
    Disable-FolderCaseSensitive -Path "C:\MyFolder"
    Disables case sensitivity for C:\MyFolder.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Write-Error "Path '$Path' does not exist or is not a directory."
        return
    }

    $result = Invoke-FsutilCommand -Arguments @('file', 'setCaseSensitiveInfo', $Path, 'disable')
    if ($null -eq $result) {
        return
    }

    if ($result.ExitCode -ne 0) {
        Write-Error "fsutil failed for '$Path': $($result.Output)"
        return
    }

    Write-Output $result.Output
}

Set-Alias caseoff Disable-FolderCaseSensitive
# Usage: caseoff
# Usage: caseoff -Path "C:\MyFolder"

function NewTempDirectory {
    <#
    .SYNOPSIS
    Creates a new temporary directory.

    .DESCRIPTION
    Creates a uniquely named directory in the system's temporary folder.
    Returns the full path to the created directory.

    .EXAMPLE
    $tempDir = New-TempDirectory
    Creates a temp directory and stores the path.

    .EXAMPLE
    New-TempDirectory -Prefix "myapp"
    Creates a temp directory with a custom prefix like "myapp_abc123".
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Prefix = "tmp"
    )

    # Get the system temp path
    $tempPath = [System.IO.Path]::GetTempPath()
    
    # Generate a unique directory name
    $tempDirName = "{0}_{1}" -f $Prefix, [System.IO.Path]::GetRandomFileName()
    $tempDirPath = Join-Path -Path $tempPath -ChildPath $tempDirName
    
    # Create the directory
    $null = New-Item -ItemType Directory -Path $tempDirPath -Force
    
    Write-Verbose "Created temporary directory: $tempDirPath"
    Set-Location -Path $tempDirPath
    # Return the path
    return $tempDirPath
}

Set-Alias tempe NewTempDirectory

#usage tempe

# <<< END: file.ps1

# >>> BEGIN: help.ps1
function Get-CustomAliasHelpEvanHahn {
    <#
    .SYNOPSIS
        Displays all custom PowerShell profile aliases with descriptions.
    
    .DESCRIPTION
        Shows a comprehensive list of all custom aliases defined in the PowerShell profile
        along with their corresponding functions and brief descriptions of what they do.
    
    .EXAMPLE
        Get-CustomAliasHelp
        Displays all custom aliases and their descriptions.
    
    .EXAMPLE
        Show-Help
        Using the short alias to display all help information.
    #>
    [CmdletBinding()]
    param()

    Write-Host "`n" -NoNewline
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "  Custom PowerShell Profile Aliases  " -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""

    # Analysis Functions
    Write-Host "ANALYSIS" -ForegroundColor Yellow
    Write-Host "--------" -ForegroundColor Yellow
    Write-Host "  analysis         " -NoNewline -ForegroundColor Green
    Write-Host "- Run Git repository diagnostic views from issue #13 (Invoke-GitRepositoryAnalysis)" -ForegroundColor White
    Write-Host ""

    # Audio/Video/Pictures Functions
    Write-Host "AUDIO/VIDEO/PICTURES" -ForegroundColor Yellow
    Write-Host "--------------------" -ForegroundColor Yellow
    Write-Host "  shrinkvid        " -NoNewline -ForegroundColor Green
    Write-Host "- Convert video to H.264 format with configurable quality (Convert-VideoToH264)" -ForegroundColor White
    Write-Host "  vidconvert       " -NoNewline -ForegroundColor Green
    Write-Host "- Convert video to both high-quality MP4 and animated GIF (Convert-VideoToMP4AndGif)" -ForegroundColor White
    Write-Host ""

    # Clipboard Functions
    Write-Host "CLIPBOARD" -ForegroundColor Yellow
    Write-Host "---------" -ForegroundColor Yellow
    Write-Host "  ccopy            " -NoNewline -ForegroundColor Green
    Write-Host "- Copy text or file content to clipboard (copyCommand)" -ForegroundColor White
    Write-Host "  ccd              " -NoNewline -ForegroundColor Green
    Write-Host "- Copy current directory path to clipboard (CopyCurDir)" -ForegroundColor White
    Write-Host "  cpwd             " -NoNewline -ForegroundColor Green
    Write-Host "- Copy current directory path to clipboard (CopyCurDir)" -ForegroundColor White
    Write-Host ""

    # Dates and Times Functions
    Write-Host "DATES & TIMES" -ForegroundColor Yellow
    Write-Host "-------------" -ForegroundColor Yellow
    Write-Host "  hoy              " -NoNewline -ForegroundColor Green
    Write-Host "- Get current date in ISO format (yyyy-MM-dd) (GetISoDate)" -ForegroundColor White
    Write-Host "  hoyt             " -NoNewline -ForegroundColor Green
    Write-Host "- Get current date and time in ISO format (yyyyMMddTHHmmss) (GetISoDateTime)" -ForegroundColor White
    Write-Host "  hoyv             " -NoNewline -ForegroundColor Green
    Write-Host "- Get current date/time as version number (1.yyyy.MMdd.HHmm) (IsoDateTimeAsVersion)" -ForegroundColor White
    Write-Host "  timer            " -NoNewline -ForegroundColor Green
    Write-Host "- Start a countdown timer for specified minutes (Start-MinuteTimer)" -ForegroundColor White
    Write-Host "  cal              " -NoNewline -ForegroundColor Green
    Write-Host "- Show a text-based calendar for the current month (Show-MonthCalendar)" -ForegroundColor White
    Write-Host "  rn               " -NoNewline -ForegroundColor Green
    Write-Host "- Show a text-based calendar for the current month (Show-MonthCalendar)" -ForegroundColor White
    Write-Host ""

    # File Functions
    Write-Host "FILE OPERATIONS" -ForegroundColor Yellow
    Write-Host "---------------" -ForegroundColor Yellow
    Write-Host "  mkcd             " -NoNewline -ForegroundColor Green
    Write-Host "- Create directory and change to it (MakeDirCD)" -ForegroundColor White
    Write-Host "  tempe            " -NoNewline -ForegroundColor Green
    Write-Host "- Create and navigate to a new temporary directory (NewTempDirectory)" -ForegroundColor White
    Write-Host ""

    # Internet Functions
    Write-Host "INTERNET" -ForegroundColor Yellow
    Write-Host "--------" -ForegroundColor Yellow
    Write-Host "  serve            " -NoNewline -ForegroundColor Green
    Write-Host "- Start dotnet-serve to host files/directories (Invoke-DotnetServe)" -ForegroundColor White
    Write-Host "  serveit          " -NoNewline -ForegroundColor Green
    Write-Host "- Start dotnet-serve to host files/directories (Invoke-DotnetServe)" -ForegroundColor White
    Write-Host "  inet             " -NoNewline -ForegroundColor Green
    Write-Host "- Enable or disable network adapters (Set-InternetConnectivity)" -ForegroundColor White
    Write-Host "  toggle-internet  " -NoNewline -ForegroundColor Green
    Write-Host "- Toggle network adapters on/off (Toggle-InternetConnectivity)" -ForegroundColor White
    Write-Host "  tinet            " -NoNewline -ForegroundColor Green
    Write-Host "- Toggle network adapters on/off (Toggle-InternetConnectivity)" -ForegroundColor White
    Write-Host "  toggle-internet2 " -NoNewline -ForegroundColor Green
    Write-Host "- Toggle network off, wait 10s, then toggle back on (Toggle-InternetConnectivity2)" -ForegroundColor White
    Write-Host "  tinet2           " -NoNewline -ForegroundColor Green
    Write-Host "- Toggle network off, wait 10s, then toggle back on (Toggle-InternetConnectivity2)" -ForegroundColor White
    Write-Host "  url              " -NoNewline -ForegroundColor Green
    Write-Host "- Parse URL into component parts (Get-UrlParts)" -ForegroundColor White
    Write-Host "  parseurl         " -NoNewline -ForegroundColor Green
    Write-Host "- Parse URL into component parts (Get-UrlParts)" -ForegroundColor White
    Write-Host ""

    # Process Management Functions
    Write-Host "PROCESS MANAGEMENT" -ForegroundColor Yellow
    Write-Host "------------------" -ForegroundColor Yellow
    Write-Host "  bb               " -NoNewline -ForegroundColor Green
    Write-Host "- Start a process in the background (Start-BackgroundProcess)" -ForegroundColor White
    Write-Host "  waitpid          " -NoNewline -ForegroundColor Green
    Write-Host "- Wait for a process to exit by PID or name (Wait-ForPID)" -ForegroundColor White
    Write-Host "  waitfor          " -NoNewline -ForegroundColor Green
    Write-Host "- Wait for a process to exit by PID or name (Wait-ForPID)" -ForegroundColor White
    Write-Host "  murder           " -NoNewline -ForegroundColor Green
    Write-Host "- Kill a process, force kill if needed (Stop-ProcessWithRetry)" -ForegroundColor White
    Write-Host "  prettypath       " -NoNewline -ForegroundColor Green
    Write-Host "- Split a file path into lines (Split-PathToLines)" -ForegroundColor White
    Write-Host ""

    # System Functions
    Write-Host "SYSTEM" -ForegroundColor Yellow
    Write-Host "------" -ForegroundColor Yellow
    Write-Host "  theme            " -NoNewline -ForegroundColor Green
    Write-Host "- Set Windows theme to Dark or Light mode (Set-WindowsMode)" -ForegroundColor White
    Write-Host ""

    # Text Functions
    Write-Host "TEXT" -ForegroundColor Yellow
    Write-Host "----" -ForegroundColor Yellow
    Write-Host "  n                " -NoNewline -ForegroundColor Green
    Write-Host "- Start Notepad with a new temp file (Start-TempNotepad)" -ForegroundColor White
    Write-Host "  nato             " -NoNewline -ForegroundColor Green
    Write-Host "- Convert text to NATO phonetic alphabet (Get-WordsFromDictionary)" -ForegroundColor White
    Write-Host ""

    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Type 'Get-Help <function-name>' for detailed help on any function" -ForegroundColor Gray
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "See this with helpEvanHahn"  
}

Set-Alias helpEvanHahn Get-CustomAliasHelpEvanHahn
# helpEvanHahn

# <<< END: help.ps1

# >>> BEGIN: httpStatus.ps1
function Get-HttpStatusMeaning {
    <#
    .SYNOPSIS
        Returns the meaning of an HTTP status code

    .DESCRIPTION
        Given an HTTP status code (for example, 200), this function writes
        back the standard reason phrase.

    .PARAMETER Code
        The HTTP status code to resolve

    .EXAMPLE
        Get-HttpStatusMeaning 200
        200 - OK
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateRange(100, 599)]
        [int]$Code
    )

    $meaning = switch ($Code) {
        100 { "Continue" }
        101 { "Switching Protocols" }
        102 { "Processing" }
        103 { "Early Hints" }
        200 { "OK" }
        201 { "Created" }
        202 { "Accepted" }
        203 { "Non-Authoritative Information" }
        204 { "No Content" }
        205 { "Reset Content" }
        206 { "Partial Content" }
        207 { "Multi-Status" }
        208 { "Already Reported" }
        226 { "IM Used" }
        300 { "Multiple Choices" }
        301 { "Moved Permanently" }
        302 { "Found" }
        303 { "See Other" }
        304 { "Not Modified" }
        305 { "Use Proxy" }
        307 { "Temporary Redirect" }
        308 { "Permanent Redirect" }
        400 { "Bad Request" }
        401 { "Unauthorized" }
        402 { "Payment Required" }
        403 { "Forbidden" }
        404 { "Not Found" }
        405 { "Method Not Allowed" }
        406 { "Not Acceptable" }
        407 { "Proxy Authentication Required" }
        408 { "Request Timeout" }
        409 { "Conflict" }
        410 { "Gone" }
        411 { "Length Required" }
        412 { "Precondition Failed" }
        413 { "Payload Too Large" }
        414 { "URI Too Long" }
        415 { "Unsupported Media Type" }
        416 { "Range Not Satisfiable" }
        417 { "Expectation Failed" }
        418 { "I'm a teapot" }
        421 { "Misdirected Request" }
        422 { "Unprocessable Content" }
        423 { "Locked" }
        424 { "Failed Dependency" }
        425 { "Too Early" }
        426 { "Upgrade Required" }
        428 { "Precondition Required" }
        429 { "Too Many Requests" }
        431 { "Request Header Fields Too Large" }
        451 { "Unavailable For Legal Reasons" }
        500 { "Internal Server Error" }
        501 { "Not Implemented" }
        502 { "Bad Gateway" }
        503 { "Service Unavailable" }
        504 { "Gateway Timeout" }
        505 { "HTTP Version Not Supported" }
        506 { "Variant Also Negotiates" }
        507 { "Insufficient Storage" }
        508 { "Loop Detected" }
        510 { "Not Extended" }
        511 { "Network Authentication Required" }
        default { "Unknown status code" }
    }

    Write-Output "$Code - $meaning"
}

Set-Alias -Name httpstatus -Value Get-HttpStatusMeaning

#usage Get-HttpStatusMeaning 200
#usage httpstatus 404

# <<< END: httpStatus.ps1

# >>> BEGIN: internet.ps1
function Invoke-DotnetServe {
    <#
    .SYNOPSIS
        Installs dotnet-serve globally and serves a file or directory
    
    .DESCRIPTION
        This function ensures dotnet-serve is installed globally, then runs it with the specified file or directory as an argument
    
    .PARAMETER Path
        The file or directory path to serve
    
    .EXAMPLE
        Invoke-DotnetServe "C:\path\to\file.html"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path
    )
    
    # If path is not provided or doesn't exist, use current directory
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path)) {
        $Path = "."
    }
    
    # If path is a file, use its parent directory
    if (Test-Path $Path -PathType Leaf) {
        $Path = Split-Path $Path -Parent
    }
    
    # Install dotnet-serve globally
    Write-Host "Installing dotnet-serve globally..." -ForegroundColor Cyan
    dotnet tool install --global dotnet-serve
    
    # Check if installation was successful or if it was already installed
    if ($LASTEXITCODE -ne 0) {
        Write-Host "dotnet-serve may already be installed or installation failed. Continuing..." -ForegroundColor Yellow
    }
    
    # Run dotnet-serve with the specified path
    Write-Host "Starting dotnet-serve with path: $Path" -ForegroundColor Green
    dotnet serve -o -d:"$Path"
}

Set-Alias serve Invoke-DotnetServe
Set-Alias serveit Invoke-DotnetServe

#usage serve
#usage serve C:\path\to\

function Set-InternetConnectivity {
    <#
    .SYNOPSIS
        Enables or disables network adapters to control internet connectivity
    
    .DESCRIPTION
        This function enables or disables all active network adapters (except Bluetooth and virtual adapters) to control internet connectivity
    
    .PARAMETER State
        Specify 'On' to enable network adapters or 'Off' to disable them
    
    .EXAMPLE
        Set-InternetConnectivity -State Off
        Disables network adapters to turn off internet
    
    .EXAMPLE
        Set-InternetConnectivity -State On
        Enables network adapters to turn on internet
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('On', 'Off')]
        [string]$State
    )
    
    # Check for administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Error "This function requires administrator privileges. Please run PowerShell as Administrator."
        return
    }
    
    
    if ($State -eq 'Off') {
        # Get physical network adapters (exclude Bluetooth, virtual adapters, etc.)
        $adapters = Get-NetAdapter | Where-Object { 
            $_.Status -ne 'Disabled' -and 
            $_.InterfaceDescription -notmatch 'Bluetooth|Virtual|VMware|VirtualBox|Hyper-V' 
        }
        
        if ($adapters.Count -eq 0) {
            Write-Warning "No active network adapters found."
            return
        }
        Write-Host "Disabling network adapters..." -ForegroundColor Yellow
        foreach ($adapter in $adapters) {
            Write-Host "  Disabling: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false
        }
        Write-Host "Internet connectivity disabled." -ForegroundColor Red
    }
    else {
        # Get disabled physical adapters to re-enable
        $disabledAdapters = Get-NetAdapter | Where-Object { 
            $_.Status -eq 'Disabled' -and 
            $_.InterfaceDescription -notmatch 'Bluetooth|Virtual|VMware|VirtualBox|Hyper-V' 
        }
        
        if ($disabledAdapters.Count -eq 0) {
            Write-Host "Network adapters are already enabled." -ForegroundColor Green
            return
        }
        
        Write-Host "Enabling network adapters..." -ForegroundColor Cyan
        foreach ($adapter in $disabledAdapters) {
            Write-Host "  Enabling: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
            Enable-NetAdapter -Name $adapter.Name -Confirm:$false
        }
        Write-Host "Internet connectivity enabled." -ForegroundColor Green
    }
    Get-NetAdapter
}

Set-Alias inet Set-InternetConnectivity

#usage inet Off
#usage inet On

function Toggle-InternetConnectivity {
    <#
    .SYNOPSIS
        Toggles network adapters on or off based on current state
    
    .DESCRIPTION
        This function automatically detects the current state of network adapters and toggles them.
        If adapters are enabled, it disables them. If disabled, it enables them.
    
    .EXAMPLE
        Toggle-InternetConnectivity
        Toggles internet connectivity
    #>
    [CmdletBinding()]
    param()
    
    # Check for administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Error "This function requires administrator privileges. Please run PowerShell as Administrator."
        return
    }
    
    # Get physical network adapters
    $enabledAdapters = Get-NetAdapter | Where-Object { 
        $_.Status -ne 'Disabled' -and 
        $_.InterfaceDescription -notmatch 'Bluetooth|Virtual|VMware|VirtualBox|Hyper-V' 
    }
    
    $disabledAdapters = Get-NetAdapter | Where-Object { 
        $_.Status -eq 'Disabled' -and 
        $_.InterfaceDescription -notmatch 'Bluetooth|Virtual|VMware|VirtualBox|Hyper-V' 
    }
    
    # Determine what to do based on current state
    if ($enabledAdapters.Count -gt 0) {
        # If any adapters are enabled, turn them off
        Write-Host "Disabling network adapters..." -ForegroundColor Yellow
        foreach ($adapter in $enabledAdapters) {
            Write-Host "  Disabling: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false
        }
        Write-Host "Internet connectivity disabled." -ForegroundColor Red
    }
    if ($disabledAdapters.Count -gt 0) {
        # If adapters are disabled, turn them on
        Write-Host "Enabling network adapters..." -ForegroundColor Cyan
        foreach ($adapter in $disabledAdapters) {
            Write-Host "  Enabling: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
            Enable-NetAdapter -Name $adapter.Name -Confirm:$false
        }
        Write-Host "Internet connectivity enabled." -ForegroundColor Green
    }
    else {
        Write-Warning "No network adapters found."
    }
}

Set-Alias toggle-internet Toggle-InternetConnectivity
Set-Alias tinet Toggle-InternetConnectivity

#usage Toggle-InternetConnectivity
#usage toggle-internet
#usage tinet

function Toggle-InternetConnectivity2 {
    <#
    .SYNOPSIS
    Toggles network adapters off, waits 10 seconds, then toggles them back on.

    .DESCRIPTION
    Calls Toggle-InternetConnectivity to disable network adapters, waits 10 seconds,
    then calls Toggle-InternetConnectivity again to re-enable them. Useful for
    quickly resetting network connectivity.

    .EXAMPLE
    Toggle-InternetConnectivity2
    Disables network adapters, waits 10 s, then re-enables them.

    .EXAMPLE
    tinet2
    Uses the alias to perform the network reset cycle.
    #>
    Toggle-InternetConnectivity
    Write-Host "Waiting 10 seconds"
    Start-Sleep  -Seconds 10
    Toggle-InternetConnectivity
}


Set-Alias toggle-internet2 Toggle-InternetConnectivity2
Set-Alias tinet2 Toggle-InternetConnectivity2

#usage Toggle-InternetConnectivity2
#usage toggle-internet2 
#usage tinet2

function Get-UrlParts {
    <#
    .SYNOPSIS
        Parses a URL into its component parts
    
    .DESCRIPTION
        This function takes a URL string and parses it into its component parts including:
        - Scheme (protocol)
        - Host (domain/hostname)
        - Port
        - Path
        - Query (parameters)
        - Fragment (hash)
        - UserInfo (username/password if present)
    
    .PARAMETER Url
        The URL string to parse
    
    .EXAMPLE
        Get-UrlParts "https://www.example.com:8080/path/to/page?param1=value1&param2=value2#section"
        
    .EXAMPLE
        Get-UrlParts "http://user:pass@localhost:3000/api/users?limit=10"
        
    .EXAMPLE
        "https://github.com/user/repo" | Get-UrlParts
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Url
    )
    
    process {
        try {
            # Use .NET Uri class for robust URL parsing
            $uri = [System.Uri]$Url
            
            # Parse query string into a hashtable
            $queryParams = @{}
            if (-not [string]::IsNullOrWhiteSpace($uri.Query)) {
                $queryString = $uri.Query.TrimStart('?')
                foreach ($param in $queryString.Split('&')) {
                    if ($param -match '^([^=]+)=(.*)$') {
                        $key = [System.Web.HttpUtility]::UrlDecode($matches[1])
                        $value = [System.Web.HttpUtility]::UrlDecode($matches[2])
                        $queryParams[$key] = $value
                    }
                    elseif ($param) {
                        $queryParams[$param] = $null
                    }
                }
            }
            
            # Create result object
            $result = [PSCustomObject]@{
                OriginalUrl     = $Url
                AbsoluteUrl     = $uri.AbsoluteUri
                Scheme          = $uri.Scheme
                Host            = $uri.Host
                Port            = $uri.Port
                Authority       = $uri.Authority
                Path            = $uri.AbsolutePath
                Query           = $uri.Query
                QueryParameters = $queryParams
                Fragment        = $uri.Fragment.TrimStart('#')
                UserInfo        = $uri.UserInfo
                IsDefaultPort   = $uri.IsDefaultPort
                IsAbsoluteUri   = $uri.IsAbsoluteUri
                DnsSafeHost     = $uri.DnsSafeHost
                Segments        = $uri.Segments
            }
            
            # Display the result in a formatted manner
            Write-Host "`n=== URL Parts ===" -ForegroundColor Cyan
            Write-Host "Original URL:    " -NoNewline -ForegroundColor Gray
            Write-Host $result.OriginalUrl -ForegroundColor White
            Write-Host "Absolute URL:    " -NoNewline -ForegroundColor Gray
            Write-Host $result.AbsoluteUrl -ForegroundColor White
            Write-Host "`nComponents:" -ForegroundColor Cyan
            Write-Host "  Scheme:        " -NoNewline -ForegroundColor Gray
            Write-Host $result.Scheme -ForegroundColor Green
            Write-Host "  Host:          " -NoNewline -ForegroundColor Gray
            Write-Host $result.Host -ForegroundColor Green
            Write-Host "  Port:          " -NoNewline -ForegroundColor Gray
            Write-Host $result.Port -ForegroundColor Green
            Write-Host "  Authority:     " -NoNewline -ForegroundColor Gray
            Write-Host $result.Authority -ForegroundColor Green
            Write-Host "  Path:          " -NoNewline -ForegroundColor Gray
            Write-Host $result.Path -ForegroundColor Green
            
            if ($result.Query) {
                Write-Host "  Query:         " -NoNewline -ForegroundColor Gray
                Write-Host $result.Query -ForegroundColor Yellow
                if ($queryParams.Count -gt 0) {
                    Write-Host "  Query Params:  " -ForegroundColor Gray
                    foreach ($key in $queryParams.Keys) {
                        Write-Host "    $key = " -NoNewline -ForegroundColor DarkGray
                        Write-Host $queryParams[$key] -ForegroundColor Yellow
                    }
                }
            }
            
            if ($result.Fragment) {
                Write-Host "  Fragment:      " -NoNewline -ForegroundColor Gray
                Write-Host "#$($result.Fragment)" -ForegroundColor Magenta
            }
            
            if ($result.UserInfo) {
                Write-Host "  UserInfo:      " -NoNewline -ForegroundColor Gray
                Write-Host $result.UserInfo -ForegroundColor Red
            }
            
            Write-Host "`nPath Segments:   " -NoNewline -ForegroundColor Cyan
            Write-Host ($result.Segments -join ' ') -ForegroundColor Green
            Write-Host "Default Port:    " -NoNewline -ForegroundColor Gray
            Write-Host $result.IsDefaultPort -ForegroundColor Green
            Write-Host ""
            
            # Return the object for further use
            return $result
        }
        catch {
            Write-Error "Failed to parse URL: $Url. Error: $_"
            return $null
        }
    }
}

Set-Alias Url Get-UrlParts
Set-Alias url Get-UrlParts
Set-Alias parseurl Get-UrlParts

#usage Get-UrlParts "https://www.example.com:8080/path/to/page?param1=value1&param2=value2#section"
#usage Url "https://github.com/user/repo"
#usage url "http://user:pass@localhost:3000/api/users?limit=10"

# <<< END: internet.ps1

# >>> BEGIN: MyWindowsUpdates.ps1
function MakeDefault {
    <#
    .SYNOPSIS
    Configures recommended default Windows Explorer and security settings.

    .DESCRIPTION
    Applies three common Windows quality-of-life settings:
    - Shows hidden files and folders in Explorer.
    - Shows file extensions for known file types.
    - Enables the Windows 11 sudo command (inline mode) via the registry.
    Restarts Explorer to apply the visibility changes immediately.

    .EXAMPLE
    MakeDefault
    Applies all default Windows settings and restarts Explorer.
    #>
    # Show hidden files and folders
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -Value 1
    Write-Host "Show hidden files and folders: enabled"

    # Show extensions for known file types
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0
    Write-Host "Show extensions for known file types: enabled"

    # Enable sudo command on Windows (requires Windows 11 24H2 or later)
    $sudoRegPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo'
    if (-not (Test-Path $sudoRegPath)) {
        New-Item -Path $sudoRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $sudoRegPath -Name 'Enabled' -Value 3
    Write-Host "Sudo command: enabled (inline mode)"

    # Restart Explorer to apply file/folder visibility changes
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Write-Host "Explorer restarted to apply changes"
}

# <<< END: MyWindowsUpdates.ps1

# >>> BEGIN: processManagement.ps1
function Start-BackgroundProcess {
	<#
	.SYNOPSIS
	Starts a command as a hidden background PowerShell process.

	.DESCRIPTION
	Launches a new PowerShell window in hidden mode, running the provided command
	line so that it runs independently without blocking the current session.

	.PARAMETER CommandLine
	The command and arguments to run in the background (joined into a single string).

	.EXAMPLE
	Start-BackgroundProcess notepad
	Starts Notepad as a hidden background process.

	.EXAMPLE
	bb "dotnet build MyProject.csproj"
	Uses the alias to build a project in the background.
	#>
	param(
		[Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
		[string[]]$CommandLine
	)
	$command = $CommandLine -join ' '
	
	#TODO Test this!	
	# $escapedArgs = $CommandLine | ForEach-Object {
	# 	"'{0}'" -f ([System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($_))
	# }
	# $command = "& " + ($escapedArgs -join ' ')
	
	Write-Host "Starting background process: $command"
	Start-Process -FilePath pwsh -ArgumentList "-WindowStyle Hidden -Command $command" -WindowStyle Hidden
}

Set-Alias bb Start-BackgroundProcess
function Wait-ForPID {
	<#
	.SYNOPSIS
	Waits until a process specified by PID or name has exited.

	.DESCRIPTION
	Polls the specified process every IntervalSeconds seconds until it is no longer
	running, then prints a message. Accepts either a numeric PID or a process name.

	.PARAMETER ProcessOrPID
	The process ID (numeric) or process name to wait for.

	.PARAMETER IntervalSeconds
	How many seconds to wait between polling checks. Default is 10.

	.EXAMPLE
	Wait-ForPID -ProcessOrPID 1234
	Waits for the process with PID 1234 to exit.

	.EXAMPLE
	waitpid notepad
	Uses the alias to wait for all Notepad processes to exit.
	#>
	param(
		[Parameter(Mandatory=$true, Position=0)]
		[Alias('Id','Name')]
		[string]$ProcessOrPID,
		[int]$IntervalSeconds = 10
	)

	 if ($ProcessOrPID -match '^[0-9]+$') {
		$RealPid = $ProcessOrPID;
	}
	else {
		$process = Get-Process -Name $ProcessOrPID -ErrorAction SilentlyContinue
		if (-not $process) {
			Write-Host "Process $ProcessOrPID is not running."
			return
		}
		$RealPid = $process.Id
	}

	while (Get-Process -Id $RealPid -ErrorAction SilentlyContinue) {
		Write-Host "Waiting for PID $RealPid to exit..."
		Start-Sleep -Seconds $IntervalSeconds
	}
	Write-Host "PID $RealPid has exited."
}
# Kills a process by PID or name. First tries normal kill, waits 10s, then force kills if still running
function Stop-ProcessWithRetry {
	<#
	.SYNOPSIS
	Kills a process by PID or name, force-killing it if it does not stop within 10 seconds.

	.DESCRIPTION
	Sends a normal termination request to the specified process via taskkill, waits 10 seconds,
	then issues a forced kill (with /F /T) if the process is still running.

	.PARAMETER ProcessOrPID
	The process ID (numeric) or process name (e.g. 'notepad') to terminate.

	.EXAMPLE
	Stop-ProcessWithRetry -ProcessOrPID notepad
	Attempts to kill all Notepad processes, force-killing if necessary.

	.EXAMPLE
	murder 1234
	Uses the alias to terminate the process with PID 1234.
	#>
	param(
		[Parameter(Mandatory=$true, Position=0)]
		[Alias('Id','Name')]
		[string]$ProcessOrPID
	)

	# Try normal kill
	Write-Host "Attempting to kill process: $ProcessOrPID"
	if ($ProcessOrPID -match '^[0-9]+$') {
		taskkill /PID $ProcessOrPID 
	} else {
		taskkill /IM $ProcessOrPID 
	}

	Start-Sleep -Seconds 10

	# Check if process is still running
	$stillRunning = $false
	if ($ProcessOrPID -match '^[0-9]+$') {
		$stillRunning = Get-Process -Id $ProcessOrPID -ErrorAction SilentlyContinue
	} else {
		$stillRunning = Get-Process -Name $ProcessOrPID -ErrorAction SilentlyContinue
	}

	if ($stillRunning) {
		Write-Host "Process still running, force killing: $ProcessOrPID"
		if ($ProcessOrPID -match '^[0-9]+$') {
			taskkill /PID $ProcessOrPID /F /T 
		} else {
			taskkill /IM $ProcessOrPID /F /T 
		}
	} else {
		Write-Host "Process $ProcessOrPID terminated successfully."
	}
}

Set-Alias murder Stop-ProcessWithRetry
Set-Alias waitpid Wait-ForPID
Set-Alias waitfor Wait-ForPID


function Split-PathToLines {
    <#
    .SYNOPSIS
    Splits a file path into individual segments, printing each on its own line.

    .DESCRIPTION
    Breaks the given path string on both forward-slash and backslash separators,
    then outputs each part as a separate line. Useful for visualizing deeply nested paths.

    .PARAMETER Path
    The file or directory path to split.

    .EXAMPLE
    Split-PathToLines -Path "C:\Users\me\Documents"
    Outputs: C:, Users, me, Documents each on a separate line.

    .EXAMPLE
    prettypath "C:\Program Files\App\bin"
    Uses the alias to print each path segment on its own line.
    #>
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Path
    )
    
    # Split by both forward slash and backslash
    $parts = $Path -split '[/\\]'
    
    # Output each part on a new line
    $parts | ForEach-Object { $_ }
}
Set-Alias prettypath Split-PathToLines
# <<< END: processManagement.ps1

# >>> BEGIN: system.ps1
function Set-WindowsMode {
    <#
    .SYNOPSIS
    Sets Windows to Dark or Light mode by writing to the registry theme settings.

    .DESCRIPTION
    Modifies the AppsUseLightTheme and SystemUsesLightTheme registry values under
    HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize so that both
    app and system UI switch to the requested color scheme.

    .PARAMETER Mode
    The color scheme to apply. Accepted values: 'Dark' or 'Light'.

    .EXAMPLE
    Set-WindowsMode -Mode Dark
    Switches Windows and applications to Dark mode.

    .EXAMPLE
    theme Light
    Uses the alias to switch to Light mode.
    #>
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet('Dark', 'Light')]
        [string]$Mode
    )
    
    $themePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    
    if ($Mode -eq 'Dark') {
        Set-ItemProperty -Path $themePath -Name AppsUseLightTheme -Value 0
        Set-ItemProperty -Path $themePath -Name SystemUsesLightTheme -Value 0
        Write-Host "Windows mode set to Dark"
    }
    else {
        Set-ItemProperty -Path $themePath -Name AppsUseLightTheme -Value 1
        Set-ItemProperty -Path $themePath -Name SystemUsesLightTheme -Value 1
        Write-Host "Windows mode set to Light"
    }
}

Set-Alias theme Set-WindowsMode
# Usage: theme Dark
# Usage: theme Light

# <<< END: system.ps1

# >>> BEGIN: text.ps1
function Start-TempNotepad {
	<#
	.SYNOPSIS
	Starts Notepad with a new temporary text file in the user's temp folder.

	.DESCRIPTION
	Creates a unique .txt file under $env:TEMP (or uses a provided file name),
	optionally writes initial content, then launches Notepad to edit it.
	Returns the full path to the temp file.

	.PARAMETER FileName
	Optional base name for the temp file. Directory parts will be ignored.
	If no extension is provided, .txt will be added.

	.PARAMETER Content
	Optional initial content to write to the file before opening Notepad.

	.PARAMETER NoLaunch
	When specified, the function will create (and optionally populate) the file
	but will not launch Notepad. Useful for scripting and tests.

	.EXAMPLE
	Start-TempNotepad
	Creates a new temp .txt file and opens it in Notepad.

	.EXAMPLE
	Start-TempNotepad -FileName notes -Content "Todo:\n- item 1"
	Creates %TEMP%\notes.txt with initial content and opens it in Notepad.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false, Position=0)]
		[string]$FileName,

		[Parameter(Mandatory=$false, Position=1)]
		[string]$Content,

		[Parameter(Mandatory=$false)]
		[switch]$NoLaunch
	)

	try {
		$tempDir = [System.IO.Path]::GetTempPath()
		if (-not (Test-Path -LiteralPath $tempDir)) {
			throw "Temp directory '$tempDir' does not exist."
		}

		# Sanitize/derive file name
		if ([string]::IsNullOrWhiteSpace($FileName)) {
			$rand = [System.IO.Path]::GetFileNameWithoutExtension([System.IO.Path]::GetRandomFileName())
			$name = "$rand.txt"
		} else {
			# Strip any directory parts
			$name = [System.IO.Path]::GetFileName($FileName)
			if ([string]::IsNullOrWhiteSpace([System.IO.Path]::GetExtension($name))) {
				$name = "$name.txt"
			}
		}

		$filePath = Join-Path -Path $tempDir -ChildPath $name

		# Ensure the file exists and optionally write content
		if ($PSBoundParameters.ContainsKey('Content')) {
			# Create/overwrite with content (UTF8 without BOM by default in pwsh)
			$null = New-Item -ItemType File -Path $filePath -Force -ErrorAction Stop
			Set-Content -LiteralPath $filePath -Value $Content -Encoding UTF8 -ErrorAction Stop
		} else {
			# Create the file if it doesn't exist
			if (-not (Test-Path -LiteralPath $filePath)) {
				$null = New-Item -ItemType File -Path $filePath -Force -ErrorAction Stop
			}
		}

		if (-not $NoLaunch) {
			Start-Process -FilePath "notepad.exe" -ArgumentList @("$filePath") -ErrorAction Stop | Out-Null
		}

		# Output the path for further automation
		return $filePath
	}
	catch {
		throw "Failed to start Notepad with temp file: $($_.Exception.Message)"
	}
}

# Short alias
Set-Alias n Start-TempNotepad


# Built-in dictionary for letters/numbers to words (NATO phonetic + digits)
$Script:DICTIONARY = @{
	'a' = 'Alfa'
	'b' = 'Bravo'
	'c' = 'Charlie'
	'd' = 'Delta'
	'e' = 'Echo'
	'f' = 'Foxtrot'
	'g' = 'Golf'
	'h' = 'Hotel'
	'i' = 'India'
	'j' = 'Juliett'
	'k' = 'Kilo'
	'l' = 'Lima'
	'm' = 'Mike'
	'n' = 'November'
	'o' = 'Oscar'
	'p' = 'Papa'
	'q' = 'Quebec'
	'r' = 'Romeo'
	's' = 'Sierra'
	't' = 'Tango'
	'u' = 'Uniform'
	'v' = 'Victor'
	'w' = 'Whiskey'
	'x' = 'X-ray'
	'y' = 'Yankee'
	'z' = 'Zulu'
	'1' = 'DIGIT 1:One'
	'2' = 'DIGIT 2:Two'
	'3' = 'DIGIT 3: Three'
	'4' = 'DIGIT 4:Four'
	'5' = 'DIGIT 5: Five'
	'6' = 'DIGIT 6: Six'
	'7' = 'DIGIT 7: Seven'
	'8' = 'DIGIT 8: Eight'
	'9' = 'DIGIT 9: Nine'
	'0' = 'DIGIT 0: Zero'
}

function Get-WordsFromDictionary {
	<#
	.SYNOPSIS
	Parses a string and returns the corresponding words from a dictionary (NATO phonetic by default).

	.DESCRIPTION
	For each character in the input string, if that character exists as a key in the
	provided dictionary (defaults to $Script:DICTIONARY), the matching word (value)
	is returned. Characters not present in the dictionary are skipped.

	.PARAMETER InputString
	The string to parse.

	.PARAMETER Dictionary
	Optional custom dictionary (hashtable) to use instead of $Script:DICTIONARY.

	.PARAMETER AsString
	When specified, returns a single string joined by -JoinWith instead of an array.

	.PARAMETER JoinWith
	The separator to use when -AsString is specified. Defaults to a single space.

	.EXAMPLE
	Get-WordsFromDictionary -InputString "abc"
	Returns: Alfa, Bravo, Charlie

	.EXAMPLE
	nato "Hi5" -AsString
	Uses the alias and returns "Hotel India DIGIT 5: Five"
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$InputString,

		[Parameter(Mandatory=$false)]
		[hashtable]$Dictionary = $Script:DICTIONARY,

		[Parameter(Mandatory=$false)]
		[switch]$AsString,

		[Parameter(Mandatory=$false)]
		[string]$JoinWith = ' '
	)

	if (-not $Dictionary) {
		throw "No DICTIONARY available. Provide -Dictionary or define `$Script:DICTIONARY."
	}

	$results = [System.Collections.Generic.List[string]]::new()
	foreach ($ch in $InputString.ToCharArray()) {
		$key = ($ch.ToString()).ToLowerInvariant()
		if ($Dictionary.ContainsKey($key)) {
			$val = [string]$Dictionary[$key]
			if ($null -ne $val -and $val -ne '') {
				[void]$results.Add($val)
			}
		}
	}

	if ($AsString) {
		return ($results -join $JoinWith)
	}
	else {
		# Ensure array output (even for 0 or 1 elements)
		return ,$results.ToArray()
	}
}

# # Optional export for module usage (only if running as a module)
# if ($ExecutionContext -and $ExecutionContext.SessionState -and $ExecutionContext.SessionState.Module) {
# 	Export-ModuleMember -Function Get-WordsFromDictionary -ErrorAction SilentlyContinue 2>$null
# }


Set-Alias nato Get-WordsFromDictionary

# <<< END: text.ps1

# >>> BEGIN: updateMe.ps1
function updateMe() {
<#
.SYNOPSIS
Downloads the latest PowerShell profile from GitHub and replaces the current profile.

.DESCRIPTION
Backs up the existing profile with a timestamped filename, then downloads the latest
unified profile from the ignatandrei/powershellProfile repository on GitHub and writes
it to $PROFILE.

.EXAMPLE
updateMe
Backs up the current profile and installs the latest version from GitHub.
#>
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

# <<< END: updateMe.ps1

# >>> BEGIN: watch.ps1
# add code that runs dotnet watch in a function
function Start-DotNetWatch {
    <#
    .SYNOPSIS
    Runs dotnet watch run for the nearest .csproj project, including Aspire AppHost projects.

    .DESCRIPTION
    Searches the given path for a .csproj file. If none is found in the current directory,
    it searches subdirectories for an Aspire AppHost project (identified by an AppHost.cs file).
    Changes to the project directory, runs 'dotnet watch run --no-hot-reload', then returns
    to the original directory.

    .PARAMETER ProjectPath
    The directory to search for a .csproj file. Defaults to the current directory.

    .EXAMPLE
    Start-DotNetWatch
    Finds and watches the .NET project in the current directory.

    .EXAMPLE
    dnw
    Uses the alias to start dotnet watch in the current directory.
    #>
    param (
        [CmdletBinding()]
        [string]$ProjectPath = (Get-Location).Path
    )
    Write-Host "Starting dotnet watch project at $ProjectPath..."
    # find if in current directory there is a .csproj or .fsproj file
    $projectFile = Get-ChildItem -Path $ProjectPath -Filter *.csproj | Select-Object -First 1
    if (-not $projectFile) {
        #find if is an Aspire project
        $projectsFile = Get-ChildItem -Path $ProjectPath -Filter *.csproj -Recurse 
        $projectFile = $projectsFile | Where-Object { 
            $dirProject = $_.DirectoryName
            #find if in the directory there is a file named AppHost.cs
            $appHost = Get-ChildItem -Path $dirProject -Filter AppHost.cs -ErrorAction SilentlyContinue 
            if($appHost) {
                Write-Host "Found Aspire project file: $($_.FullName)"
                return $true
            }
            return $false
        } | Select-Object -First 1    
    }
    if (-not $projectFile) {
        Write-Host "Error: No .csproj file found in $ProjectPath or an Aspire project in subdirectories."
        return
    }
    $projectDir = $projectFile.DirectoryName
    $currentDir = Get-Location
    if( $projectDir -ne $currentDir.Path) {
        Push-Location $projectDir
    }
    try{
        dotnet watch run --no-hot-reload
    }
    finally {
        if( $projectDir -ne $currentDir.Path) {
            Pop-Location
        }
    }
       
}

Set-Alias -Name dnw -Value Start-DotNetWatch

function dnwr([string]$ProjectPath = (Get-Location).Path   ) {
    <#
    .SYNOPSIS
    Runs dotnet watch run with --no-restore for the current or specified .NET project.

    .DESCRIPTION
    Calls Start-DotNetWatch with the --no-restore flag, skipping the NuGet restore step.
    Useful when dependencies are already restored and you want faster startup.

    .EXAMPLE
    dnwr
    Starts dotnet watch run --no-restore in the current directory.

    .EXAMPLE
    dnwr -ProjectPath C:\MyProject
    Starts dotnet watch run --no-restore for the project at the specified path.
    #>
    Invoke-Command -ScriptBlock { Start-DotNetWatch  $ProjectPath "--no-restore" }
}

# <<< END: watch.ps1

# >>> BEGIN: zip.ps1
# add code that unzips files in a function
function Start-Unzip {
    <#
    .SYNOPSIS
    Extracts all zip files in the specified directory into a destination folder.

    .DESCRIPTION
    Finds every *.zip file in the given path, extracts each one into a destination
    subfolder (default: ExtractedFiles), and on Windows opens the folder in Explorer.

    .PARAMETER ProjectPath
    The directory to search for zip files. Defaults to the current directory.

    .PARAMETER DestinationFolder
    The name of the subfolder inside ProjectPath where files will be extracted.
    Defaults to "ExtractedFiles".

    .EXAMPLE
    Start-Unzip
    Extracts all zip files in the current directory into .\ExtractedFiles.

    .EXAMPLE
    uz -DestinationFolder "Output"
    Uses the alias to extract zip files into .\Output.
    #>
    [CmdletBinding()]
    param (
        
        [string]$ProjectPath = (Get-Location).Path,
        [string]$DestinationFolder = "ExtractedFiles"
    )
    Write-Host "Starting unzip at $ProjectPath..."
    # find if in current directory there is a zip file
    $zipFiles = Get-ChildItem -Path $ProjectPath -Filter *.zip
    $fullDestinationPath = Join-Path $ProjectPath $DestinationFolder

    if (!(Test-Path -Path $fullDestinationPath)) {
        New-Item -ItemType Directory -Path $fullDestinationPath | Out-Null
    }
    foreach ($zipFile in $zipFiles) {
        $extractPath = $fullDestinationPath
        Expand-Archive -Path $zipFile.FullName -DestinationPath $extractPath -Force
    }
    if ($zipFiles.Count -eq 0) {
        Write-Host "No zip files found in $ProjectPath."
    } else {
        Write-Host "Extracted $($zipFiles.Count) zip file(s) to $extractPath."
        if ($IsWindows) {
            Write-Host "Opening extracted folder..."
            explorer $extractPath
        }
    }
    
       
}

Set-Alias -Name uz -Value Start-Unzip
# <<< END: zip.ps1

# >>> BEGIN: generated-help.ps1
function Show-ProfileHelpHtml {
    [CmdletBinding()]
    param(
        [string]$Url = 'https://ignatandrei.github.io/powershellProfile/functions.html'
    )

    Start-Process -FilePath $Url
}

Set-Alias profilehelp Show-ProfileHelpHtml
Write-Host "Run 'profilehelp' to view the profile documentation."
# <<< END: generated-help.ps1

