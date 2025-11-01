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

    $highlightToday = $true
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