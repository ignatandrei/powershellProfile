# add code that runs dotnet watch in a function
function Start-DotNetWatch {
  
    Write-Host "Starting dotnet watch  project at $ProjectPath..."
    # find if in current directory there isStart-DotNetWatch a .csproj or .fsproj file
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
    $projectDir = $projectFile.DirectoryName
    $currentDir = Get-Location
    if( $projectDir -ne $currentDir.Path) {
        Push-Location $projectDir
    }
    try{
        dotnet watch run --no-hot-reload
    }
    finally {
        Pop-Location
    }
       
}

Set-Alias -Name dnw -Value Start-DotNetWatch