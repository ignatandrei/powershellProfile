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

function Invoke-FsutilCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $command = @('fsutil.exe') + $Arguments
    if (-not $isElevated) {
        $sudo = Get-Command -Name 'sudo.exe' -ErrorAction Ignore
        if ($null -eq $sudo) {
            Write-Error "sudo.exe is required to run fsutil when the current PowerShell session is not elevated."
            return $null
        }

        $command = @('sudo.exe') + $command
    }

    $output = & $command[0] $command[1..($command.Length - 1)] 2>&1

    [PSCustomObject]@{
        Output = $output
        ExitCode = $LASTEXITCODE
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
