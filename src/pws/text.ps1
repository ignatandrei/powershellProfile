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
