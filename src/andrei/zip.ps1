# add code that unzips files in a function
function Start-Unzip {
    <#
    .SYNOPSIS
    Extracts all zip files in the specified directory into a destination folder.

    .DESCRIPTION
    Finds every *.zip file in the given path, extracts each one into a destination
    subfolder (default: ExtractedFiles), and on Windows opens the folder in Explorer.

    .PARAMETER ProjectPath
    The directory to search for zip files. Defaults to the current directory.

    .PARAMETER DestinationFolder
    The name of the subfolder inside ProjectPath where files will be extracted.
    Defaults to "ExtractedFiles".

    .EXAMPLE
    Start-Unzip
    Extracts all zip files in the current directory into .\ExtractedFiles.

    .EXAMPLE
    uz -DestinationFolder "Output"
    Uses the alias to extract zip files into .\Output.
    #>
    [CmdletBinding()]
    param (
        
        [string]$ProjectPath = (Get-Location).Path,
        [string]$DestinationFolder = "ExtractedFiles"
    )
    Write-Host "Starting unzip at $ProjectPath..."
    # find if in current directory there is a zip file
    $zipFiles = Get-ChildItem -Path $ProjectPath -Filter *.zip
    $fullDestinationPath = Join-Path $ProjectPath $DestinationFolder

    if (!(Test-Path -Path $fullDestinationPath)) {
        New-Item -ItemType Directory -Path $fullDestinationPath | Out-Null
    }
    foreach ($zipFile in $zipFiles) {
        $extractPath = $fullDestinationPath
        Expand-Archive -Path $zipFile.FullName -DestinationPath $extractPath -Force
    }
    if ($zipFiles.Count -eq 0) {
        Write-Host "No zip files found in $ProjectPath."
    } else {
        Write-Host "Extracted $($zipFiles.Count) zip file(s) to $extractPath."
        if ($IsWindows) {
            Write-Host "Opening extracted folder..."
            explorer $extractPath
        }
    }
    
       
}

Set-Alias -Name uz -Value Start-Unzip