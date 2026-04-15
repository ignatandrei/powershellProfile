function MakeDefault {
    # Show hidden files and folders
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -Value 1
    Write-Host "Show hidden files and folders: enabled"

    # Show extensions for known file types
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0
    Write-Host "Show extensions for known file types: enabled"

    # Enable sudo command on Windows (requires Windows 11 24H2 or later)
    $sudoRegPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo'
    if (-not (Test-Path $sudoRegPath)) {
        New-Item -Path $sudoRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $sudoRegPath -Name 'Enabled' -Value 3
    Write-Host "Sudo command: enabled (inline mode)"

    # Restart Explorer to apply file/folder visibility changes
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Write-Host "Explorer restarted to apply changes"
}
