<#
.SYNOPSIS
    Can be used to add a list of files to a list of git repositories
.DESCRIPTION
    The git repositories are to be specified as a list of URLs in a .txt file.
    The script clones each git respository, specified in a single line
    of the supplied text file. It then checks out the specified branch,
    adds the list of files to the root path of the repositories and
    commits/pushes the changes with the CommitMessage
#>
param(
    # Path to .txt file with URLs to git repositories
    [Parameter(Mandatory = $true)]
    [string]$RepoListPath,
    # Target path where the repositories should be cloned
    [Parameter(Mandatory = $true)]
    [string]$CloneTarget,
    # Branch that should be used 
    [Parameter(Mandatory = $true)]
    [string]$Branch,
    # List of new files that should be added to the repositories
    [Parameter(Mandatory = $true)]
    [string[]]$NewFiles,
    # Commit message for the added files
    [Parameter(Mandatory = $true)]
    [string]$CommitMessage
)

if (!(Test-Path $RepoListPath)) {
    Write-Error "'RepoListPath' is not a valid path to text document with git repository urls"
    exit
}

if (!(Test-Path $CloneTarget)) {
    new-item -ItemType Directory $CloneTarget -Force
    if (!(Test-Path $CloneTarget)) {
        Write-Error "'$CloneTarget' could not be created successfully. Please check the path!"
        exit
    }
}

# Prints a parameter with name,value to console
Function printParam([string]$name, $value) {
    Write-Host "$name`: " -NoNewline 
    Write-Host -ForegroundColor Green $value
}

# Check if user wants to continue
printParam -name "Number of Repositories to process" -value (Get-content $RepoListPath).Length
printParam -name "Target-Folder" -value (Resolve-Path $CloneTarget)
printParam -name "Branch to checkout" -value $Branch
printParam -name "Files to add" -value (Resolve-Path $NewFiles)
if (!($continue = Read-Host "Are you sure you want to procede with the above parameters? (Y/n)")) {
    $continue = 'Y'
}
if ($continue -ne 'Y') { exit }

# Clear the target path
(Get-ChildItem $CloneTarget) | ForEach-Object {
    Remove-Item -Recurse $_ -Force
}

(get-content $RepoListPath) | ForEach-Object {
    Set-Location $CloneTarget
    $repoName = (split-path -Leaf $_)
    write-host -ForegroundColor Yellow "1) Cloning $_"
    git clone $_ -q

    if (!(Test-Path $CloneTarget\$repoName)) {
        Write-Error "'$_' is not a valid URL of a git repository"
        return
    }
    
    Set-Location $CloneTarget\$repoName
    
    write-host -ForegroundColor Yellow "2) Checkout branch $Branch"
    git checkout $Branch -q
    if (!([string](git symbolic-ref HEAD)).EndsWith($Branch)) {
        Write-Host -ForegroundColor Red "Branch '$Branch' does not exist in Repository '$repoName'"
        Write-Host "-----------------------------------------"
        Set-Location ..
        remove-item -Recurse -Force $repoName
        # quit processing for this repository
        return
    }

    Write-Host -ForegroundColor Yellow "3) Adding new files"
    foreach ($newFile in $NewFiles) {
        Copy-Item -Path $newFile -Destination $CloneTarget\$repoName
    }
    git add -A 2>&1
    
    Write-Host -ForegroundColor Yellow "4) Create commit: '$CommitMessage'"
    git commit -m"$CommitMessage" -q
    
    Write-Host -ForegroundColor Yellow "4) Pushing changes to remote"
    git push origin -q
    Set-Location ..
    remove-item -Recurse -Force $repoName
    
    Write-Host -ForegroundColor DarkYellow "Finished $repoName"
    Write-Host "-----------------------------------------------------"
}