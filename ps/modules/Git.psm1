<# 
    Checks if the directory is a git directory
#>
Function isGit() {
    param(
        [Parameter()]
        [string]$path
    )
    (Get-ChildItem -Hidden  -Path $path) | Foreach-Object { 
        if ($_.Name -eq ".git") { 
            return $true 
        } 
    }
    return $false
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
    $branchExists = $null -ne (git ls-remote --heads $Remote $Branch 2>0)
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

    if (isGit($Path)) {
        return existsRemoteBranch -GitPath $Path -Remote $Remote -Branch $Branch
    }
    else {
        Write-Error "There is not git repository at path $Path"
    }
    return $false    
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
        [string] $Path,
        # Optional name of branch to which the repository should be resetted to
        [Parameter()]
        [string] $Branch
    )

}

Export-ModuleMember *-*