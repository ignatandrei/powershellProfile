function Install-Psmux {
	<#
	.SYNOPSIS
		Installs psmux via winget

	.DESCRIPTION
		Runs 'winget install psmux' to install the psmux terminal multiplexer.

	.EXAMPLE
		Install-Psmux

	.EXAMPLE
		psmux-install
	#>
	[CmdletBinding()]
	param()

	Write-Host "Installing psmux via winget..." -ForegroundColor Cyan
	winget install psmux
}

Set-Alias -Name psmux-install -Value Install-Psmux

#usage Install-Psmux
#usage psmux-install

function Install-Squad {
	<#
	.SYNOPSIS
		Installs the Squad CLI via npm

	.DESCRIPTION
		Runs 'npm i -g @bradygaster/squad-cli' to install the Squad CLI tool globally.

	.EXAMPLE
		Install-Squad

	.EXAMPLE
		squad-install
	#>
	[CmdletBinding()]
	param()

	Write-Host "Installing Squad CLI via npm..." -ForegroundColor Cyan
	npm i -g @bradygaster/squad-cli
}

Set-Alias -Name squad-install -Value Install-Squad

#usage Install-Squad
#usage squad-install

function Install-Sbx {
	<#
	.SYNOPSIS
		Installs Docker sbx via winget

	.DESCRIPTION
		Runs 'winget install -h Docker.sbx' to silently install Docker sbx.
		Also prints a reminder to enable the HypervisorPlatform Windows feature if needed.

	.EXAMPLE
		Install-Sbx

	.EXAMPLE
		sbx-install
	#>
	[CmdletBinding()]
	param()

	Write-Host "Installing sbx via winget..." -ForegroundColor Cyan
	winget install -h Docker.sbx
    Write-Host "You may need to enable the Hypervisor Platform feature..." -ForegroundColor Cyan
    Write-Host "Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All"

}

Set-Alias -Name sbx-install -Value Install-Sbx

#usage Install-Sbx
#usage sbx-install

function Get-CurrentGitUrl {
	<#
	.SYNOPSIS
		Returns the remote URL of the current Git repository

	.DESCRIPTION
		Resolves the repository root from the given path and returns the URL
		of the specified remote (default: origin).

	.PARAMETER Path
		Path inside the Git repository. Defaults to the current directory.

	.PARAMETER Remote
		Name of the remote to query. Defaults to 'origin'.

	.EXAMPLE
		Get-CurrentGitUrl

	.EXAMPLE
		giturl

	.EXAMPLE
		Get-CurrentGitUrl -Remote upstream
	#>
	[CmdletBinding()]
	param(
		[string]$Path = (Get-Location).Path,
		[string]$Remote = "origin"
	)

	$repoRoot = git -C $Path rev-parse --show-toplevel 2>$null
	if (-not $repoRoot) {
		Write-Warning "Path is not inside a Git repository."
		return
	}

	$url = git -C $repoRoot config --get ("remote.{0}.url" -f $Remote) 2>$null
	if (-not $url) {
		Write-Warning ("Remote '{0}' not found." -f $Remote)
		return
	}

	$url
}

Set-Alias -Name giturl -Value Get-CurrentGitUrl

#usage Get-CurrentGitUrl
#usage giturl
#usage Get-CurrentGitUrl -Remote upstream

function Get-CurrentGitName {
	<#
	.SYNOPSIS
		Returns the name of the current Git repository

	.DESCRIPTION
		Resolves the repository root from the given path and returns the
		folder name that represents the repository name.

	.PARAMETER Path
		Path inside the Git repository. Defaults to the current directory.

	.EXAMPLE
		Get-CurrentGitName

	.EXAMPLE
		gitname
	#>
	[CmdletBinding()]
	param(
		[string]$Path = (Get-Location).Path
	)

	$repoRoot = git -C $Path rev-parse --show-toplevel 2>$null
	if (-not $repoRoot) {
		Write-Warning "Path is not inside a Git repository."
		return
	}

	Split-Path -Path $repoRoot -Leaf
}

Set-Alias -Name gitname -Value Get-CurrentGitName

#usage Get-CurrentGitName
#usage gitname

function New-BranchWorkspace {
	<#
	.SYNOPSIS
		Clones the current Git repo into a new branch-specific workspace folder

	.DESCRIPTION
		Goes one level above the current directory, creates a folder named
		'[repoName]_[branchName]', clones the current remote into it, then
		checks out the specified branch (creating it if it does not exist on
		the remote). Finally echoes 'sbx run copilot'.

	.PARAMETER BranchName
		The name of the branch to check out or create inside the new workspace.

	.EXAMPLE
		New-BranchWorkspace myFeature

	.EXAMPLE
		branchws myFeature
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string]$BranchName
	)

	# Resolve current repo URL and name
	$gitUrl = Get-CurrentGitUrl
	if (-not $gitUrl) { return }

	$gitRepoName = Get-CurrentGitName
	if (-not $gitRepoName) { return }

	# Build target folder one level above the current directory
	$parentFolder = Split-Path -Path (Get-Location).Path -Parent
	$targetFolder = Join-Path $parentFolder ("{0}_{1}" -f $gitRepoName, $BranchName)

	Write-Host "Creating workspace folder: $targetFolder" -ForegroundColor Cyan
	New-Item -ItemType Directory -Force -Path $targetFolder | Out-Null

	# Clone the repository into the new folder
	Write-Host "Cloning $gitUrl into $targetFolder ..." -ForegroundColor Cyan
	git clone $gitUrl $targetFolder

	if ($LASTEXITCODE -ne 0) {
		Write-Error "git clone failed."
		return
	}

	Push-Location $targetFolder

	try {
		# Check whether the branch already exists on the remote
		$remoteBranch = git ls-remote --heads origin $BranchName 2>$null
		if ($remoteBranch) {
			Write-Host "Branch '$BranchName' exists on remote. Checking out..." -ForegroundColor Green
			git checkout $BranchName
		}
		else {
			Write-Host "Branch '$BranchName' does not exist. Creating..." -ForegroundColor Yellow
			git checkout -b $BranchName
		}

		Write-Host ""
		Write-Host "sbx run copilot"
	}
	finally {
		Pop-Location
	}
}

Set-Alias -Name branchws -Value New-BranchWorkspace

#usage New-BranchWorkspace myFeature
#usage branchws myFeature


