function Clear-NodeModules {
    <#
    .SYNOPSIS
    Removes all node_modules directories under a given path.

    .DESCRIPTION
    Recursively searches for node_modules directories starting from the specified
    root path and deletes them. Useful for reclaiming disk space in Node.js projects.

    .PARAMETER Path
    The root path to search from. Defaults to the current directory.

    .EXAMPLE
    Clear-NodeModules
    Removes all node_modules folders under the current directory.

    .EXAMPLE
    Clear-NodeModules -Path "C:\Projects"
    Removes all node_modules folders under C:\Projects.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    Get-ChildItem -Path $Path -Filter 'node_modules' -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\node_modules\\node_modules' } |
        ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove')) {
                Write-Host "Removing $($_.FullName)"
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
            }
        }
}

Set-Alias cleannpm Clear-NodeModules
# Usage: cleannpm
# Usage: cleannpm -Path "C:\Projects"

function Clear-DotNetBuildFolders {
    <#
    .SYNOPSIS
    Removes all bin and obj directories under a given path.

    .DESCRIPTION
    Recursively searches for bin and obj directories starting from the specified
    root path and deletes them. Useful for cleaning .NET build artifacts.

    .PARAMETER Path
    The root path to search from. Defaults to the current directory.

    .EXAMPLE
    Clear-DotNetBuildFolders
    Removes all bin and obj folders under the current directory.

    .EXAMPLE
    Clear-DotNetBuildFolders -Path "C:\Projects"
    Removes all bin and obj folders under C:\Projects.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    Get-ChildItem -Path $Path -Include 'bin', 'obj' -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove')) {
                Write-Host "Removing $($_.FullName)"
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
            }
        }
}

Set-Alias cleandotnet Clear-DotNetBuildFolders
# Usage: cleandotnet
# Usage: cleandotnet -Path "C:\Projects"

function Clear-JavaBuildFolders {
    <#
    .SYNOPSIS
    Removes Java/JVM build output directories (target, build) under a given path.

    .DESCRIPTION
    Recursively searches for target (Maven/Gradle) and build (Gradle) directories
    starting from the specified root path and deletes them. Useful for cleaning
    Java, Kotlin, Scala, and other JVM project build artifacts.

    .PARAMETER Path
    The root path to search from. Defaults to the current directory.

    .EXAMPLE
    Clear-JavaBuildFolders
    Removes all target and build folders under the current directory.

    .EXAMPLE
    Clear-JavaBuildFolders -Path "C:\Projects"
    Removes all target and build folders under C:\Projects.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    Get-ChildItem -Path $Path -Include 'target', 'build' -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object {
            # Reduce false positives by only including build folders whose parent contains Maven/Gradle descriptors
            $parent = $_.Parent.FullName
            (Test-Path (Join-Path $parent 'pom.xml')) -or
            (Test-Path (Join-Path $parent 'build.gradle')) -or
            (Test-Path (Join-Path $parent 'build.gradle.kts')) -or
            (Test-Path (Join-Path $parent 'settings.gradle')) -or
            (Test-Path (Join-Path $parent 'settings.gradle.kts'))
        } |
        ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove')) {
                Write-Host "Removing $($_.FullName)"
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
            }
        }
}

Set-Alias cleanjava Clear-JavaBuildFolders
# Usage: cleanjava
# Usage: cleanjava -Path "C:\Projects"

function Clear-PythonBuildFolders {
    <#
    .SYNOPSIS
    Removes Python build/cache artifacts under a given path.

    .DESCRIPTION
    Recursively searches for __pycache__ directories, .pytest_cache directories,
    .mypy_cache directories, dist directories, and *.egg-info directories under
    the specified root path and deletes them.

    .PARAMETER Path
    The root path to search from. Defaults to the current directory.

    .EXAMPLE
    Clear-PythonBuildFolders
    Removes all Python build artifacts under the current directory.

    .EXAMPLE
    Clear-PythonBuildFolders -Path "C:\Projects"
    Removes all Python build artifacts under C:\Projects.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    $patterns = @('__pycache__', '.pytest_cache', '.mypy_cache', 'dist', '*.egg-info')

    foreach ($pattern in $patterns) {
        Get-ChildItem -Path $Path -Filter $pattern -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            ForEach-Object {
                if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove')) {
                    Write-Host "Removing $($_.FullName)"
                    Remove-Item -LiteralPath $_.FullName -Recurse -Force
                }
            }
    }

    # Remove compiled .pyc files
    Get-ChildItem -Path $Path -Filter '*.pyc' -Recurse -File -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove')) {
                Write-Host "Removing $($_.FullName)"
                Remove-Item -LiteralPath $_.FullName -Force
            }
        }
}

Set-Alias cleanpython Clear-PythonBuildFolders
# Usage: cleanpython
# Usage: cleanpython -Path "C:\Projects"

function Clear-RustBuildFolders {
    <#
    .SYNOPSIS
    Removes Rust/Cargo build output directories under a given path.

    .DESCRIPTION
    Recursively searches for target directories that belong to Rust/Cargo projects
    (identified by a sibling Cargo.toml) under the specified root path and deletes them.

    .PARAMETER Path
    The root path to search from. Defaults to the current directory.

    .EXAMPLE
    Clear-RustBuildFolders
    Removes all Rust target folders under the current directory.

    .EXAMPLE
    Clear-RustBuildFolders -Path "C:\Projects"
    Removes all Rust target folders under C:\Projects.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    Get-ChildItem -Path $Path -Filter 'target' -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object {
            Test-Path (Join-Path $_.Parent.FullName 'Cargo.toml')
        } |
        ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove')) {
                Write-Host "Removing $($_.FullName)"
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
            }
        }
}

Set-Alias cleanrust Clear-RustBuildFolders
# Usage: cleanrust
# Usage: cleanrust -Path "C:\Projects"

function Clear-AllBuildFolders {
    <#
    .SYNOPSIS
    Removes build/cache artifacts for all supported languages under a given path.

    .DESCRIPTION
    Calls Clear-NodeModules, Clear-DotNetBuildFolders, Clear-JavaBuildFolders,
    Clear-PythonBuildFolders, and Clear-RustBuildFolders for the specified root path.
    Covers Node.js (node_modules), .NET (bin, obj), Java/JVM (target, build),
    Python (__pycache__, .pytest_cache, .mypy_cache, dist, *.egg-info, *.pyc),
    and Rust (target).

    .PARAMETER Path
    The root path to search from. Defaults to the current directory.

    .EXAMPLE
    Clear-AllBuildFolders
    Removes all known build artifacts under the current directory.

    .EXAMPLE
    Clear-AllBuildFolders -Path "C:\Projects"
    Removes all known build artifacts under C:\Projects.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    $childParams = @{
        Path = $Path
    }

    if ($PSBoundParameters.ContainsKey('WhatIf')) {
        $childParams['WhatIf'] = $true
    }

    if ($PSBoundParameters.ContainsKey('Confirm')) {
        $childParams['Confirm'] = $true
    }
    Write-Host "=== Cleaning Node.js (node_modules) ==="
    Clear-NodeModules @childParams

    Write-Host "=== Cleaning .NET (bin, obj) ==="
    Clear-DotNetBuildFolders @childParams

    Write-Host "=== Cleaning Java/JVM (target, build) ==="
    Clear-JavaBuildFolders @childParams

    Write-Host "=== Cleaning Python (__pycache__, *.pyc, dist, *.egg-info) ==="
    Clear-PythonBuildFolders @childParams

    Write-Host "=== Cleaning Rust (target) ==="
    Clear-RustBuildFolders @childParams
}

Set-Alias cleanall Clear-AllBuildFolders
# Usage: cleanall
# Usage: cleanall -Path "C:\Projects"
