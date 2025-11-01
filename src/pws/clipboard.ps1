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
            $lines.Add($content)
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
    Write-Host $CommandParts.Count
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

