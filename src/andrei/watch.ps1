# add code that runs dotnet watch in a function
function Start-DotNetWatch {
    <#
    .SYNOPSIS
    Runs dotnet watch run for the nearest .csproj project, including Aspire AppHost projects.

    .DESCRIPTION
    Searches the given path for a .csproj file. If none is found in the current directory,
    it searches subdirectories for an Aspire AppHost project (identified by an AppHost.cs file).
    Changes to the project directory, runs 'dotnet watch run --no-hot-reload', then returns
    to the original directory.

    .PARAMETER ProjectPath
    The directory to search for a .csproj file. Defaults to the current directory.

    .EXAMPLE
    Start-DotNetWatch
    Finds and watches the .NET project in the current directory.

    .EXAMPLE
    dnw
    Uses the alias to start dotnet watch in the current directory.
    #>
    param (
        [CmdletBinding()]
        [string]$ProjectPath = (Get-Location).Path
    )
    Write-Host "Starting dotnet watch project at $ProjectPath..."
    # find if in current directory there is a .csproj or .fsproj file
    $projectFile = Get-ChildItem -Path $ProjectPath -Filter *.csproj | Select-Object -First 1
    if (-not $projectFile) {
        #find if is an Aspire project
        $projectsFile = Get-ChildItem -Path $ProjectPath -Filter *.csproj -Recurse 
        $projectFile = $projectsFile | Where-Object { 
            $dirProject = $_.DirectoryName
            #find if in the directory there is a file named AppHost.cs
            $appHost = Get-ChildItem -Path $dirProject -Filter AppHost.cs -ErrorAction SilentlyContinue 
            if($appHost) {
                Write-Host "Found Aspire project file: $($_.FullName)"
                return $true
            }
            return $false
        } | Select-Object -First 1    
    }
    if (-not $projectFile) {
        Write-Host "Error: No .csproj file found in $ProjectPath or an Aspire project in subdirectories."
        return
    }
    $projectDir = $projectFile.DirectoryName
    $currentDir = Get-Location
    if( $projectDir -ne $currentDir.Path) {
        Push-Location $projectDir
    }
    try{
        dotnet watch run --no-hot-reload
    }
    finally {
        if( $projectDir -ne $currentDir.Path) {
            Pop-Location
        }
    }
       
}

Set-Alias -Name dnw -Value Start-DotNetWatch

function dnwr([string]$ProjectPath = (Get-Location).Path   ) {
    <#
    .SYNOPSIS
    Runs dotnet watch run with --no-restore for the current or specified .NET project.

    .DESCRIPTION
    Calls Start-DotNetWatch with the --no-restore flag, skipping the NuGet restore step.
    Useful when dependencies are already restored and you want faster startup.

    .EXAMPLE
    dnwr
    Starts dotnet watch run --no-restore in the current directory.

    .EXAMPLE
    dnwr -ProjectPath C:\MyProject
    Starts dotnet watch run --no-restore for the project at the specified path.
    #>
    Invoke-Command -ScriptBlock { Start-DotNetWatch  $ProjectPath "--no-restore" }
}
