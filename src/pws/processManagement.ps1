function Start-BackgroundProcess {
	param(
		[Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
		[string[]]$CommandLine
	)

	$command = $CommandLine -join ' '
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
		$RealPid = (Get-Process -Name $ProcessOrPID).Id
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