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