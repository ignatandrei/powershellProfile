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
