function Invoke-DotnetServe {
    <#
    .SYNOPSIS
        Installs dotnet-serve globally and serves a file or directory
    
    .DESCRIPTION
        This function ensures dotnet-serve is installed globally, then runs it with the specified file or directory as an argument
    
    .PARAMETER Path
        The file or directory path to serve
    
    .EXAMPLE
        Invoke-DotnetServe "C:\path\to\file.html"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path
    )
    
    # If path is not provided or doesn't exist, use current directory
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path)) {
        $Path = "."
    }
    
    # If path is a file, use its parent directory
    if (Test-Path $Path -PathType Leaf) {
        $Path = Split-Path $Path -Parent
    }
    
    # Install dotnet-serve globally
    Write-Host "Installing dotnet-serve globally..." -ForegroundColor Cyan
    dotnet tool install --global dotnet-serve
    
    # Check if installation was successful or if it was already installed
    if ($LASTEXITCODE -ne 0) {
        Write-Host "dotnet-serve may already be installed or installation failed. Continuing..." -ForegroundColor Yellow
    }
    
    # Run dotnet-serve with the specified path
    Write-Host "Starting dotnet-serve with path: $Path" -ForegroundColor Green
    dotnet serve -o -d:"$Path"
}

Set-Alias serve Invoke-DotnetServe
Set-Alias serveit Invoke-DotnetServe

#usage serve
#usage serve C:\path\to\

function Set-InternetConnectivity {
    <#
    .SYNOPSIS
        Enables or disables network adapters to control internet connectivity
    
    .DESCRIPTION
        This function enables or disables all active network adapters (except Bluetooth and virtual adapters) to control internet connectivity
    
    .PARAMETER State
        Specify 'On' to enable network adapters or 'Off' to disable them
    
    .EXAMPLE
        Set-InternetConnectivity -State Off
        Disables network adapters to turn off internet
    
    .EXAMPLE
        Set-InternetConnectivity -State On
        Enables network adapters to turn on internet
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('On', 'Off')]
        [string]$State
    )
    
    # Check for administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Error "This function requires administrator privileges. Please run PowerShell as Administrator."
        return
    }
    
    
    if ($State -eq 'Off') {
        # Get physical network adapters (exclude Bluetooth, virtual adapters, etc.)
        $adapters = Get-NetAdapter | Where-Object { 
            $_.Status -ne 'Disabled' -and 
            $_.InterfaceDescription -notmatch 'Bluetooth|Virtual|VMware|VirtualBox|Hyper-V' 
        }
        
        if ($adapters.Count -eq 0) {
            Write-Warning "No active network adapters found."
            return
        }
        Write-Host "Disabling network adapters..." -ForegroundColor Yellow
        foreach ($adapter in $adapters) {
            Write-Host "  Disabling: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false
        }
        Write-Host "Internet connectivity disabled." -ForegroundColor Red
    }
    else {
        # Get disabled physical adapters to re-enable
        $disabledAdapters = Get-NetAdapter | Where-Object { 
            $_.Status -eq 'Disabled' -and 
            $_.InterfaceDescription -notmatch 'Bluetooth|Virtual|VMware|VirtualBox|Hyper-V' 
        }
        
        if ($disabledAdapters.Count -eq 0) {
            Write-Host "Network adapters are already enabled." -ForegroundColor Green
            return
        }
        
        Write-Host "Enabling network adapters..." -ForegroundColor Cyan
        foreach ($adapter in $disabledAdapters) {
            Write-Host "  Enabling: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
            Enable-NetAdapter -Name $adapter.Name -Confirm:$false
        }
        Write-Host "Internet connectivity enabled." -ForegroundColor Green
    }
    Get-NetAdapter
}

Set-Alias inet Set-InternetConnectivity

#usage inet Off
#usage inet On

function Toggle-InternetConnectivity {
    <#
    .SYNOPSIS
        Toggles network adapters on or off based on current state
    
    .DESCRIPTION
        This function automatically detects the current state of network adapters and toggles them.
        If adapters are enabled, it disables them. If disabled, it enables them.
    
    .EXAMPLE
        Toggle-InternetConnectivity
        Toggles internet connectivity
    #>
    [CmdletBinding()]
    param()
    
    # Check for administrator privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Error "This function requires administrator privileges. Please run PowerShell as Administrator."
        return
    }
    
    # Get physical network adapters
    $enabledAdapters = Get-NetAdapter | Where-Object { 
        $_.Status -ne 'Disabled' -and 
        $_.InterfaceDescription -notmatch 'Bluetooth|Virtual|VMware|VirtualBox|Hyper-V' 
    }
    
    $disabledAdapters = Get-NetAdapter | Where-Object { 
        $_.Status -eq 'Disabled' -and 
        $_.InterfaceDescription -notmatch 'Bluetooth|Virtual|VMware|VirtualBox|Hyper-V' 
    }
    
    # Determine what to do based on current state
    if ($enabledAdapters.Count -gt 0) {
        # If any adapters are enabled, turn them off
        Write-Host "Disabling network adapters..." -ForegroundColor Yellow
        foreach ($adapter in $enabledAdapters) {
            Write-Host "  Disabling: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false
        }
        Write-Host "Internet connectivity disabled." -ForegroundColor Red
    }
    if ($disabledAdapters.Count -gt 0) {
        # If adapters are disabled, turn them on
        Write-Host "Enabling network adapters..." -ForegroundColor Cyan
        foreach ($adapter in $disabledAdapters) {
            Write-Host "  Enabling: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Gray
            Enable-NetAdapter -Name $adapter.Name -Confirm:$false
        }
        Write-Host "Internet connectivity enabled." -ForegroundColor Green
    }
    else {
        Write-Warning "No network adapters found."
    }
}

Set-Alias toggle-internet Toggle-InternetConnectivity
Set-Alias tinet Toggle-InternetConnectivity

#usage Toggle-InternetConnectivity
#usage toggle-internet
#usage tinet

function Toggle-InternetConnectivity2 {
    Toggle-InternetConnectivity
    Write-Host "Waiting 10 seconds"
    Start-Sleep  -Seconds 10
    Toggle-InternetConnectivity
}


Set-Alias toggle-internet2 Toggle-InternetConnectivity2
Set-Alias tinet2 Toggle-InternetConnectivity2

#usage Toggle-InternetConnectivity2
#usage toggle-internet2 
#usage tinet2

function Get-UrlParts {
    <#
    .SYNOPSIS
        Parses a URL into its component parts
    
    .DESCRIPTION
        This function takes a URL string and parses it into its component parts including:
        - Scheme (protocol)
        - Host (domain/hostname)
        - Port
        - Path
        - Query (parameters)
        - Fragment (hash)
        - UserInfo (username/password if present)
    
    .PARAMETER Url
        The URL string to parse
    
    .EXAMPLE
        Get-UrlParts "https://www.example.com:8080/path/to/page?param1=value1&param2=value2#section"
        
    .EXAMPLE
        Get-UrlParts "http://user:pass@localhost:3000/api/users?limit=10"
        
    .EXAMPLE
        "https://github.com/user/repo" | Get-UrlParts
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Url
    )
    
    process {
        try {
            # Use .NET Uri class for robust URL parsing
            $uri = [System.Uri]$Url
            
            # Parse query string into a hashtable
            $queryParams = @{}
            if (-not [string]::IsNullOrWhiteSpace($uri.Query)) {
                $queryString = $uri.Query.TrimStart('?')
                foreach ($param in $queryString.Split('&')) {
                    if ($param -match '^([^=]+)=(.*)$') {
                        $key = [System.Web.HttpUtility]::UrlDecode($matches[1])
                        $value = [System.Web.HttpUtility]::UrlDecode($matches[2])
                        $queryParams[$key] = $value
                    }
                    elseif ($param) {
                        $queryParams[$param] = $null
                    }
                }
            }
            
            # Create result object
            $result = [PSCustomObject]@{
                OriginalUrl     = $Url
                AbsoluteUrl     = $uri.AbsoluteUri
                Scheme          = $uri.Scheme
                Host            = $uri.Host
                Port            = $uri.Port
                Authority       = $uri.Authority
                Path            = $uri.AbsolutePath
                Query           = $uri.Query
                QueryParameters = $queryParams
                Fragment        = $uri.Fragment.TrimStart('#')
                UserInfo        = $uri.UserInfo
                IsDefaultPort   = $uri.IsDefaultPort
                IsAbsoluteUri   = $uri.IsAbsoluteUri
                DnsSafeHost     = $uri.DnsSafeHost
                Segments        = $uri.Segments
            }
            
            # Display the result in a formatted manner
            Write-Host "`n=== URL Parts ===" -ForegroundColor Cyan
            Write-Host "Original URL:    " -NoNewline -ForegroundColor Gray
            Write-Host $result.OriginalUrl -ForegroundColor White
            Write-Host "Absolute URL:    " -NoNewline -ForegroundColor Gray
            Write-Host $result.AbsoluteUrl -ForegroundColor White
            Write-Host "`nComponents:" -ForegroundColor Cyan
            Write-Host "  Scheme:        " -NoNewline -ForegroundColor Gray
            Write-Host $result.Scheme -ForegroundColor Green
            Write-Host "  Host:          " -NoNewline -ForegroundColor Gray
            Write-Host $result.Host -ForegroundColor Green
            Write-Host "  Port:          " -NoNewline -ForegroundColor Gray
            Write-Host $result.Port -ForegroundColor Green
            Write-Host "  Authority:     " -NoNewline -ForegroundColor Gray
            Write-Host $result.Authority -ForegroundColor Green
            Write-Host "  Path:          " -NoNewline -ForegroundColor Gray
            Write-Host $result.Path -ForegroundColor Green
            
            if ($result.Query) {
                Write-Host "  Query:         " -NoNewline -ForegroundColor Gray
                Write-Host $result.Query -ForegroundColor Yellow
                if ($queryParams.Count -gt 0) {
                    Write-Host "  Query Params:  " -ForegroundColor Gray
                    foreach ($key in $queryParams.Keys) {
                        Write-Host "    $key = " -NoNewline -ForegroundColor DarkGray
                        Write-Host $queryParams[$key] -ForegroundColor Yellow
                    }
                }
            }
            
            if ($result.Fragment) {
                Write-Host "  Fragment:      " -NoNewline -ForegroundColor Gray
                Write-Host "#$($result.Fragment)" -ForegroundColor Magenta
            }
            
            if ($result.UserInfo) {
                Write-Host "  UserInfo:      " -NoNewline -ForegroundColor Gray
                Write-Host $result.UserInfo -ForegroundColor Red
            }
            
            Write-Host "`nPath Segments:   " -NoNewline -ForegroundColor Cyan
            Write-Host ($result.Segments -join ' ') -ForegroundColor Green
            Write-Host "Default Port:    " -NoNewline -ForegroundColor Gray
            Write-Host $result.IsDefaultPort -ForegroundColor Green
            Write-Host ""
            
            # Return the object for further use
            return $result
        }
        catch {
            Write-Error "Failed to parse URL: $Url. Error: $_"
            return $null
        }
    }
}

Set-Alias Url Get-UrlParts
Set-Alias url Get-UrlParts
Set-Alias parseurl Get-UrlParts

#usage Get-UrlParts "https://www.example.com:8080/path/to/page?param1=value1&param2=value2#section"
#usage Url "https://github.com/user/repo"
#usage url "http://user:pass@localhost:3000/api/users?limit=10"
