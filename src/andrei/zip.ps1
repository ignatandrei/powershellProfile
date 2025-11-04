# add code that unzips files in a function
function Start-Unzip {
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