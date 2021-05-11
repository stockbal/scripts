######################################
# Checks if the directory is a git directory
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

#######################################
# Checks if the given branch exists in the given remote
Function existsRemoteBranch() {
    param(
        [Parameter()]
        [string]$gitPath, 
        [Parameter()]
        [string]$remote, 
        [Parameter()]
        [string]$branch
    )
    Set-Location gitPath
    $branchExists = ($(git ls-remote --heads $remote $branch ) -ne "")
    Set-Location ..
    return $branchExists
}
#######################################
# Retrieves the full path of an i18n folder inside the 
# provided path
Function getI18nFolder([string]$path) {
    (Get-ChildItem $path -Recurse) | Foreach-Object {
        if ($_.Name -eq "i18n") {
            return $_.FullName
        }
    }
}

Function copyI18nFolder() {
    param(
        [Parameter()]
        [string]$Path, 
        [Parameter()]
        [string]$TargetFolder, 
        [Parameter()]
        [bool]$CreateTarget
    )
    $repoName = (Split-Path $Path -Leaf)
    $i18n = getI18nFolder -path $Path
    
    # Should the target folder be created ?
    if ($CreateTarget) { 
        new-item -ItemType Directory $TargetFolder\$repoName -Force
    }
    # Copy Folder to new path
    if ($i18n) {
        Copy-Item -Path $i18n -Recurse -Destination $TargetFolder\$repoName -ErrorAction SilentlyContinue
    }
}

#######################################
# Exports i18n folders from a ui5 application
# to another location
Function Export-UI5Translations() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Target,
        [Parameter()]
        [bool]$CreateTarget = $true
    )

    if (Test-Path $Path\package.json) {
        # this is obviously an app directory
        copyI18nFolder -Path (Resolve-Path $Path).Path -TargetFolder $Target -CreateTarget $CreateTarget
    }
    else {
        (Get-ChildItem -Path $Path) | Foreach-Object {
            copyI18nFolder -Path $_.FullName -TargetFolder $Target -CreateTarget $CreateTarget
        }
    }
}

Function Get-ExistsGitRemoteBranch() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Remote,
        [Parameter(Mandatory)]
        [string]$Branch
    )

    if (!$Remote) {
        $Remote = "origin"
    }

    if (isGit($Path)) {
        if (existsRemoteBranch($Path, $Remote, $Branch)) {
            "Remote Branch '$Branch' exists"
            return
        }
    }
    else {
        # perform concurrent determination of the remote branch
        #$resultDict = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new();
        #Get-ChildItem -Path . | ForEach-Object -parallel {
        #    Set-Location $_
        #    "Determining branch info for $_"
        #    $branch_exists = 
        #    $repo_info = "" | Select release_2011
        #    If ($branch_exists) { $repo_info.release_2011 = "X" }
        #    $dict = $using:resultDict
        #    [void]$dict.TryAdd($_.Name, $repo_info)
        #    Set-Location ..
        #}
        #$resultDict
    }
    
}

Export-ModuleMember *-*