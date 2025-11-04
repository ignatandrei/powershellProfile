# add code that unzips a files  in a function
function Start-Unzip {
    param (
        [CmdletBinding()]
        [string]$ProjectPath = (Get-Location).Path,
        [string]$DestinationFolder = "ExtractedFiles"
    )
    Write-Host "Starting unzip  at $ProjectPath..."
    # find if in current directory there is azip file
    $zipFiles = Get-ChildItem -Path $ProjectPath -Filter *.zip
    if (!(Test-Path -Path $DestinationFolder)) {
        New-Item -ItemType Directory -Path $DestinationFolder
    }
    foreach ($zipFile in $zipFiles) {
        $extractPath = $DestinationFolder
        Expand-Archive -Path $zipFile.FullName -DestinationPath $extractPath -Force
    }
    explorer $extractPath
       
}

Set-Alias -Name uz -Value Start-Unzip