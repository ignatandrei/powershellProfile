# ============================================================================
# Unified PowerShell Profile
# Generated: 2025-11-01 17:09:20 +02:00
# Repository: (local run)
# Source folder: src/pws
# Files concatenated in alphabetical order
# ============================================================================

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
    $currentDir = Get-Location
    $null = Set-Clipboard -Value $currentDir.Path
    Write-Host "Copied current directory to clipboard: $($currentDir.Path)" -ForegroundColor Green
}
Set-Alias ccd CopyCurDir
Set-Alias cpwd CopyCurDir
#usage ccd
#usage cpwd


# <<< END: clipboard.ps1

# >>> BEGIN: datesAndTimes.ps1
function GetISoDate {
    # Returns the current date and time in ISO 8601 format
    return (Get-Date).ToString("yyyy-MM-dd")
}
function GetISoDateTime {
    # Returns the current date and time in ISO 8601 format
    return (Get-Date).ToString("yyyyMMddTHHmmss")
}
function IsoDateTimeAsVersion {
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
helpEvanHahn
# <<< END: help.ps1

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

# >>> BEGIN: processManagement.ps1
function Start-BackgroundProcess {
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

.EXAMPLE
Start-TempNotepad -Content "Hello" -NoLaunch

Creates a temp .txt file with the content but does not launch Notepad; returns the path.
#>
function Start-TempNotepad {
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

<#
.SYNOPSIS
Parses a string and returns the corresponding words from DICTIONARY.

.DESCRIPTION
For each character in the input string, if that character exists as a key in the
provided dictionary (defaults to $Script:DICTIONARY), the matching word (value)
is returned. Characters not present in the dictionary are skipped.

.PARAMETER InputString
The string to parse.

.PARAMETER Dictionary
Optional custom dictionary (hashtable) to use instead of $Script:DICTIONARY.
Keys should be single-character strings; values are the words to return.

.PARAMETER AsString
When specified, returns a single string joined by -JoinWith instead of an array.

.PARAMETER JoinWith
The separator to use when -AsString is specified. Defaults to a single space.

.EXAMPLE
Get-WordsFromDictionary -InputString "abc"

Returns: Alfa, Bravo, Charlie

.EXAMPLE
Get-WordsFromDictionary -InputString "Hi-5" -AsString

Returns: "Hotel India Five"
#>
function Get-WordsFromDictionary {
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

