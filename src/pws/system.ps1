function Set-WindowsMode {
    <#
    .SYNOPSIS
    Sets Windows to Dark or Light mode by writing to the registry theme settings.

    .DESCRIPTION
    Modifies the AppsUseLightTheme and SystemUsesLightTheme registry values under
    HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize so that both
    app and system UI switch to the requested color scheme.

    .PARAMETER Mode
    The color scheme to apply. Accepted values: 'Dark' or 'Light'.

    .EXAMPLE
    Set-WindowsMode -Mode Dark
    Switches Windows and applications to Dark mode.

    .EXAMPLE
    theme Light
    Uses the alias to switch to Light mode.
    #>
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
