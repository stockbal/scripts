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

$ErrorActionPreference

if (!(Test-Path $RepoListPath)) {
    Write-Error "'RepoListPath' is not a valid path to text document with git repository urls"
    exit
}
if (!(Test-Path $CloneTarget)) {
    if (!$Force) {
        Write-Error "'CloneTarget' is not a valid path for cloning the repositories. If it should be created provide the parameter -Force"
        exit
    }
}

# (get-content $repoList) | ForEach-Object {
#     Set-Location $root
#     $repoName = (split-path -Leaf $_)
#     write-host -ForegroundColor Yellow "1) Cloning $_"
#     git clone $_ --quiet
#     Set-Location $root\$repoName
#     write-host -ForegroundColor Yellow "2) Checkout branch $branchName"
#     git checkout $branchName --quiet
#     if (!([string](git symbolic-ref HEAD)).EndsWith($branchName)) {
#         Write-Host -ForegroundColor Red "Branch '$branchName' does not exist in Repository '$repoName'"
#         Write-Host "-----------------------------------------"
#         continue
#     }
#     Write-Host -ForegroundColor Yellow "3) Adding TEW translation file"
#     Copy-Item -Path $translationFile -Destination $root\$repoName
#     git add translation_v2.json 2>&1
#     git commit -m"chore: add TEW translation config" 2>&1
#     Write-Host -ForegroundColor Yellow "4) Pushing changes to remote"
#     git push origin 2>&1
    
#     Set-Location ..
#     remove-item -Recurse -Force $repoName
#     Write-Host -ForegroundColor Yellow "Finished $repoName"
#     Write-Host "-----------------------------------------------------"
# }