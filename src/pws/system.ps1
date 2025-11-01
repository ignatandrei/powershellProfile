function Set-WindowsMode {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet('Dark', 'Light')]
        [string]$Mode
    )
    
    $themePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    
    if ($Mode -eq 'Dark') {
        Set-ItemProperty -Path $themePath -Name AppsUseLightTheme -Value 0
        Set-ItemProperty -Path $themePath -Name SystemUsesLightTheme -Value 0
        Write-Host "Windows mode set to Dark"
    }
    else {
        Set-ItemProperty -Path $themePath -Name AppsUseLightTheme -Value 1
        Set-ItemProperty -Path $themePath -Name SystemUsesLightTheme -Value 1
        Write-Host "Windows mode set to Light"
    }
}

Set-Alias theme Set-WindowsMode
# Usage: theme Dark
# Usage: theme Light
