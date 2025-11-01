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
