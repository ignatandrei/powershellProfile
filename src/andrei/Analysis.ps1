function Get-GitAnalysisRepositoryRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path
    )

    $repoRoot = git -C $Path rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
        Write-Error "Path '$Path' is not inside a Git repository."
        return $null
    }

    return $repoRoot.Trim()
}

function ConvertTo-GroupedFileCount {
    [CmdletBinding()]
    param(
        [string[]]$FilePaths,

        [Parameter(Mandatory = $false)]
        [int]$Top = 20
    )

    if (-not $FilePaths) {
        return @()
    }

    $FilePaths |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Group-Object |
        Sort-Object -Property Count, Name -Descending |
        Select-Object -First $Top |
        ForEach-Object {
            [pscustomobject]@{
                Count = $_.Count
                File  = $_.Name
            }
        }
}

function Get-GitChurnHotspots {
    <#
    .SYNOPSIS
        Lists the most frequently changed files in a Git repository.

    .DESCRIPTION
        PowerShell equivalent of:
        git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20

        Uses Group-Object instead of uniq -c to count how often each file appears in
        the Git history for the selected time window.

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .PARAMETER Since
        Git --since filter. Defaults to '1 year ago'.

    .PARAMETER Top
        Maximum number of files to return. Defaults to 20.

    .EXAMPLE
        Get-GitChurnHotspots

    .EXAMPLE
        Get-GitChurnHotspots -Since "6 months ago" -Top 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$Since = "1 year ago",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 500)]
        [int]$Top = 20
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    $gitArgs = @('-C', $repoRoot, 'log', '--format=format:', '--name-only')
    if (-not [string]::IsNullOrWhiteSpace($Since)) {
        $gitArgs += "--since=$Since"
    }

    $files = & git @gitArgs 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to read Git log for churn hotspots."
        return
    }

    ConvertTo-GroupedFileCount -FilePaths $files -Top $Top
}

function Get-GitContributorsByCommitCount {
    <#
    .SYNOPSIS
        Lists contributors ranked by non-merge commit count.

    .DESCRIPTION
        PowerShell equivalent of:
        git shortlog -sn --no-merges

        Returns parsed objects so the output can be formatted, filtered, or exported.

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .PARAMETER Since
        Optional Git --since filter, for example '6 months ago'.

    .EXAMPLE
        Get-GitContributorsByCommitCount

    .EXAMPLE
        Get-GitContributorsByCommitCount -Since "6 months ago"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$Since
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    $gitArgs = @('-C', $repoRoot, 'shortlog', '-sn', '--no-merges')
    if (-not [string]::IsNullOrWhiteSpace($Since)) {
        $gitArgs += "--since=$Since"
    }

    $lines = & git @gitArgs 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to read Git shortlog."
        return
    }

    foreach ($line in $lines) {
        if ($line -match '^\s*(?<Count>\d+)\s+(?<Author>.+)$') {
            [pscustomobject]@{
                CommitCount = [int]$Matches['Count']
                Author      = $Matches['Author'].Trim()
            }
        }
    }
}

function Get-GitBugHotspots {
    <#
    .SYNOPSIS
        Lists files most frequently touched by bug-fix commits.

    .DESCRIPTION
        PowerShell equivalent of:
        git log -i -E --grep="fix|bug|broken" --name-only --format='' | sort | uniq -c | sort -nr | head -20

        Uses Git commit message filtering plus Group-Object to replace uniq -c.

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .PARAMETER Pattern
        Regex used with git log --grep. Defaults to 'fix|bug|broken'.

    .PARAMETER Top
        Maximum number of files to return. Defaults to 20.

    .EXAMPLE
        Get-GitBugHotspots

    .EXAMPLE
        Get-GitBugHotspots -Pattern "fix|bug|broken|defect" -Top 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$Pattern = 'fix|bug|broken',

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 500)]
        [int]$Top = 20
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    $gitArgs = @('-C', $repoRoot, 'log', '-i', '-E', "--grep=$Pattern", '--name-only', '--format=format:')
    $files = & git @gitArgs 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to read Git log for bug hotspots."
        return
    }

    ConvertTo-GroupedFileCount -FilePaths $files -Top $Top
}

function Get-GitCommitVelocityByMonth {
    <#
    .SYNOPSIS
        Shows commit counts grouped by month.

    .DESCRIPTION
        PowerShell equivalent of:
        git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c

        Uses Group-Object to count commits per month.

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .EXAMPLE
        Get-GitCommitVelocityByMonth
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    $months = & git -C $repoRoot log '--format=%ad' '--date=format:%Y-%m' 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to read Git log for monthly commit velocity."
        return
    }

    $months |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Group-Object |
        Sort-Object -Property Name |
        ForEach-Object {
            [pscustomobject]@{
                Month       = $_.Name
                CommitCount = $_.Count
            }
        }
}

function Get-GitFirefightingCommits {
    <#
    .SYNOPSIS
        Lists likely firefighting commits such as hotfixes or rollbacks.

    .DESCRIPTION
        PowerShell equivalent of:
        git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'

        This version uses git log --grep so it works natively in PowerShell.

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .PARAMETER Since
        Git --since filter. Defaults to '1 year ago'.

    .PARAMETER Pattern
        Regex used with git log --grep. Defaults to 'revert|hotfix|emergency|rollback'.

    .EXAMPLE
        Get-GitFirefightingCommits

    .EXAMPLE
        Get-GitFirefightingCommits -Since "6 months ago"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$Since = "1 year ago",

        [Parameter(Mandatory = $false)]
        [string]$Pattern = 'revert|hotfix|emergency|rollback'
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    $gitArgs = @('-C', $repoRoot, 'log', '--oneline', '-i', '-E', "--grep=$Pattern")
    if (-not [string]::IsNullOrWhiteSpace($Since)) {
        $gitArgs += "--since=$Since"
    }

    $lines = & git @gitArgs 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to read Git log for firefighting commits."
        return
    }

    foreach ($line in $lines) {
        if ($line -match '^(?<Commit>[0-9a-f]+)\s+(?<Message>.+)$') {
            [pscustomobject]@{
                Commit  = $Matches['Commit']
                Message = $Matches['Message']
            }
        }
    }
}

function Invoke-GitRepositoryAnalysis {
    <#
    .SYNOPSIS
        Runs the five Git diagnostics from issue #13 in PowerShell.

    .DESCRIPTION
        Translates the commands from
        https://piechowski.io/post/git-commands-before-reading-code/
        into native PowerShell-friendly helpers.

        The main differences are:
        - Group-Object replaces uniq -c
        - git log --grep replaces grep-based filtering where practical

        The command prints five sections:
        - churn hotspots
        - contributor ranking
        - bug hotspots
        - monthly commit velocity
        - firefighting commits

    .PARAMETER Path
        Path inside the Git repository. Defaults to the current directory.

    .PARAMETER Since
        Shared Git --since filter for churn and firefighting views. Defaults to '1 year ago'.

    .PARAMETER Top
        Number of rows shown for hotspot sections. Defaults to 20.

    .EXAMPLE
        Invoke-GitRepositoryAnalysis

    .EXAMPLE
        analysis -Since "6 months ago" -Top 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$Since = "1 year ago",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 500)]
        [int]$Top = 20
    )

    $repoRoot = Get-GitAnalysisRepositoryRoot -Path $Path
    if (-not $repoRoot) { return }

    Write-Host ""
    Write-Host "Git repository analysis: $repoRoot" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "=== What Changes the Most ===" -ForegroundColor Yellow
    $churn = @(Get-GitChurnHotspots -Path $repoRoot -Since $Since -Top $Top)
    if ($churn.Count -gt 0) {
        $churn | Format-Table -AutoSize | Out-Host
    }
    else {
        Write-Host "No churn data found." -ForegroundColor DarkYellow
    }
    Write-Host ""

    Write-Host "=== Who Built This ===" -ForegroundColor Yellow
    $contributors = @(Get-GitContributorsByCommitCount -Path $repoRoot)
    if ($contributors.Count -gt 0) {
        $contributors | Format-Table -AutoSize | Out-Host
    }
    else {
        Write-Host "No contributor data found." -ForegroundColor DarkYellow
    }
    Write-Host ""

    Write-Host "=== Where Do Bugs Cluster ===" -ForegroundColor Yellow
    $bugHotspots = @(Get-GitBugHotspots -Path $repoRoot -Top $Top)
    if ($bugHotspots.Count -gt 0) {
        $bugHotspots | Format-Table -AutoSize | Out-Host
    }
    else {
        Write-Host "No bug hotspot data found." -ForegroundColor DarkYellow
    }
    Write-Host ""

    Write-Host "=== Is This Project Accelerating or Dying ===" -ForegroundColor Yellow
    $velocity = @(Get-GitCommitVelocityByMonth -Path $repoRoot)
    if ($velocity.Count -gt 0) {
        $velocity | Format-Table -AutoSize | Out-Host
    }
    else {
        Write-Host "No commit velocity data found." -ForegroundColor DarkYellow
    }
    Write-Host ""

    Write-Host "=== How Often Is the Team Firefighting ===" -ForegroundColor Yellow
    $firefighting = @(Get-GitFirefightingCommits -Path $repoRoot -Since $Since)
    if ($firefighting.Count -gt 0) {
        $firefighting | Format-Table -AutoSize | Out-Host
    }
    else {
        Write-Host "No firefighting commits found." -ForegroundColor DarkYellow
    }
}

Set-Alias -Name analysis -Value Invoke-GitRepositoryAnalysis

#usage Get-GitChurnHotspots
#usage Get-GitContributorsByCommitCount
#usage Get-GitBugHotspots
#usage Get-GitCommitVelocityByMonth
#usage Get-GitFirefightingCommits
#usage Invoke-GitRepositoryAnalysis
#usage analysis
