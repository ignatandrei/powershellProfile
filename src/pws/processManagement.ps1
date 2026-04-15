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