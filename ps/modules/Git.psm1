Function runGit([string[]]$GitArgs, [switch]$Verbose) {
    if ($PSBoundParameters['Verbose']) {
        git $GitArgs
    }
    else {
        git $GitArgs -q 2>&1 | Out-Null
    }
}
<#
    Collects the full paths of a list of relative paths
#>
Function collectPaths([string[]]$RelativePath) {
    $finalPaths = New-Object System.Collections.ArrayList
    foreach ($item in $RelativePath) {
        $resolvedPaths = Resolve-Path $item
        if ($resolvedPaths.GetType().IsArray) {
            $finalPaths.AddRange($resolvedPaths.Path) | Out-Null
        }
        else {
            $finalPaths.Add($resolvedPaths.Path) | Out-Null
        }
    }
    return $finalPaths
}

<#
    Checks if the given branch exists in the given remote
#>
Function existsRemoteBranch() {
    param(
        [Parameter()]
        [string]$GitPath, 
        [Parameter()]
        [string]$Remote, 
        [Parameter()]
        [string]$Branch
    )
    $currentLocation = Get-Location
    Set-Location $GitPath
    $branchExists = $null -ne (git ls-remote --heads $Remote $Branch 2>&1)
    Set-Location $currentLocation
    return $branchExists
}

<#
.SYNOPSIS
    Tests if the given given git repository has a certain
    remote branch
#>
Function Test-GitRemoteBranchExists() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [string]$Remote = "origin",
        [Parameter(Mandatory = $false)]
        [string]$Branch = "main"
    )

    $Path = Resolve-Path $Path

    if ((Test-Path -Path "$Path\.git")) {
        return existsRemoteBranch -GitPath $Path -Remote $Remote -Branch $Branch
    }
    else {
        Write-Error "There is not git repository at path $Path"
    }
    return $false    
}

<#
    Checks if a branch exists
#>
Function Test-GitBranchExists() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Branch
    )
    return ([string](git symbolic-ref HEAD)).EndsWith($Branch)
}

<#
.SYNOPSIS
    Resets the local changes in a repository and retrieves the current
    information from the current remote branch
#>
Function Reset-GitLocal() {
    [CmdletBinding()]
    param (
        # Path to a valid Git repository
        [Parameter(Mandatory = $true)]
        [string[]] $Path
    )
    $cwd = Get-Location
    $repoPaths = collectPaths -RelativePath $Path
    foreach ($repo in $repoPaths) {
        Set-Location -Path $repo
        Write-Host "Resetting repo at ""$repo""..." -ForegroundColor Cyan
        if (!(Test-Path -Path "$repo\.git")) {
            Write-Error "The directory $repo does not appear to be a git repository"
        }
        else {
            runGit -GitArgs reset, HEAD, --hard -Verbose:($PSBoundParameters['Verbose'])
            runGit -GitArgs pull -Verbose:($PSBoundParameters['Verbose'])
            Write-Host
        }
        Set-Location $cwd
    }
    Set-Location $cwd
}

<#
.SYNOPSIS
    Clones a single or multiple repositories
#>
Function Invoke-CloneGitRepos() {
    [CmdletBinding()]
    param (
        # Path to a valid Git repository
        [Parameter(Mandatory = $true)]
        [string[]] $URL,
        # Optional name of branch to which the repository should be resetted to
        [Parameter()]
        [string] $Branch,
        # Target folder to clone the repositories to
        [Parameter(Mandatory = $true)]
        [string] $Target
    )

    $cwd = Get-Location

    if (!(Test-Path $Target)) {
        New-Item -ItemType Directory $Target -Force | Out-Null
    }

    Set-Location $Target

    foreach ($u in $URL) {
        $repoName = Split-Path -Path $u -Leaf
        if ((Test-Path ($repoName)) -and ((Get-ChildItem $repoName).Length -ge 1)) {
            Write-Error "There already exists a non-empty directory with name '$repoName'"
            Write-Host
        }
        else {
            Write-Host "> Cloning '$repoName'..." -ForegroundColor Yellow
            runGit -GitArgs clone, $u -Verbose:($PSBoundParameters['Verbose'])
            Write-Host "Cloned $repoName repository" -ForegroundColor Green
            Write-Host
        }
    }

    Set-Location $cwd
}

<#
.SYNOPSIS
    Creates a new remote branch for a single or multiple git repositories
#>
Function New-GitRemoteBranch() {
    [CmdletBinding()]
    param (
        # Path(s) to a valid Git repository
        [Parameter()]
        [string[]] $Path,
        # URLs to Git repositories
        [Parameter()]
        [string[]] $URL,
        # Working directory for cloning repositories
        [Parameter()]
        [string] $WorkingDir = ".",
        # Name of the base branch for the new remote branch
        [Parameter(Mandatory = $true)]
        [string] $BaseBranch,
        # Name the new target branch
        [Parameter(Mandatory = $true)]
        [string] $TargetBranch
    )

    # remember current location
    $cwd = Get-Location

    if (($Path -and $URL) -or (!$Path -and !$URL)) {
        Write-Error "You must pass a value to -Path or -URL but not both"
        return
    }
    $urlMode = $false
    # Determine the paths to the git repositories
    if ($Path) {
        $repoPaths = (collectPaths $Path)
    }
    else {
        $urlMode = $true
        if (!(Test-Path $WorkingDir)) {
            New-Item -ItemType Directory $WorkingDir | Out-Null
            if (!(Test-Path $WorkingDir)) {
                return
            }
        }
        $WorkingDir = (Resolve-Path $WorkingDir)
        $repoPaths = $URL
    }

    # process the repositories
    $repoCount = $repoPaths.Count
    $i = 0
    foreach ($repoPath in $repoPaths) {
        $i++
        $repoName = (Split-Path -Leaf $repoPath)
        Write-Host
        Write-Host "[$i/$repoCount] Processing path '$repoPath'" -ForegroundColor Yellow
        if ($urlMode) {
            Set-Location $WorkingDir
            if ((Test-Path ($repoName)) -and ((Get-ChildItem $repoName).Length -ge 1)) {
                Write-Error "There already exists a non-empty directory with name '$repoName'"
                Write-Host
                continue
            }
            Write-Host " > Cloning..." -ForegroundColor Cyan
            # git clone $repoPath -q
            runGit -GitArgs clone, $repoPath -Verbose:($PSBoundParameters['Verbose'])
            Set-Location $repoName
        }
        else {
            Set-Location $repoPath
        }

        # Now the base branch should be checked out
        if (!(Test-GitBranchExists -Branch $BaseBranch)) {
            Write-Error "Branch $Branch does not exist in repository"
            continue
        }

        # check if the remote branch already exists
        Write-Host " > Checking remote branch existence '$TargetBranch'" -ForegroundColor Cyan
        if ((existsRemoteBranch -GitPath . -Remote "origin" -Branch $TargetBranch)) {
            Write-Error "Remote branch '$TargetBranch' already exists"
            continue
        }

        # create the new branch
        Write-Host " > Create new branch '$TargetBranch'" -ForegroundColor Cyan
        # git branch $TargetBranch origin/$BaseBranch -q 2>&1
        runGit -GitArgs branch, $TargetBranch, origin/$BaseBranch -Verbose:($PSBoundParameters['Verbose'])
        # git push -u origin $TargetBranch -q 2>&1 | Out-Null
        runGit -GitArgs push, -u, origin, $TargetBranch -Verbose:($PSBoundParameters['Verbose']) 
        if ((existsRemoteBranch -GitPath . -Remote "origin" -Branch $TargetBranch)) {
            Write-Host "   Remote branch '$TargetBranch' created for '$repoName'" -ForegroundColor Green
        }
    }
    Set-Location $cwd

    if ($WorkingDir -ne $cwd -and !($deleteConfirm = Read-Host "Delete working directory '$WorkingDir' (Y/n)")) {
        $deleteConfirm = 'Y'
    }
    if ($deleteConfirm -eq 'Y') {
        Remove-Item -Recurse -Force $WorkingDir
    }
}

Export-ModuleMember *-*