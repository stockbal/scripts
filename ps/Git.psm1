Function Get-ExistsGitRemoteBranch() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Remote="origin",
        [Parameter(Mandatory)]
        [string]$Branch
    )

    if (isGit($Path)) {
        if (existsRemoteBranch($Path, $Remote, $Branch)) {
            "Remote Branch '$Branch' exists"
            return
        }
    } else {
        # perform concurrent determination of the remote branch
        #$resultDict = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new();
        #gci -Path . | ForEach-Object -parallel {
        #    cd $_
        #    "Determining branch info for $_"
        #    $branch_exists = 
        #    $repo_info = "" | Select release_2011
        #    If ($branch_exists) { $repo_info.release_2011 = "X" }
        #    $dict = $using:resultDict
        #    [void]$dict.TryAdd($_.Name, $repo_info)
        #    cd ..
        #}
        #$resultDict
    }
    
}

######################################
# Checks if the directory is a git directory
function Private:isGit([string]$path) {
    (gci -Hidden  -Path $path) | % { 
        if ($_.Name -eq ".git") { 
            return $true 
        } 
    }
    return $false
}

#######################################
# Checks if the given branch exists in the given remote
function Private:existsRemoteBranch([string]$gitPath, [string]$remote, [string]$branch) {
    cd gitPath
    $branchExists = ($(git ls-remote --heads $remote $branch ) -ne "")
    cd ..
    return $branchExists
}