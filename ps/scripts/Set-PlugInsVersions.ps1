<#
.SYNOPSIS
    Sets versions of plug-in Projects via maven-tycho plug-in
#>
param(
    # Path to .txt file with paths to git repositories
    [Parameter(Mandatory = $true)]
    [string]$RepoListPath,
    # Base path to installed repositories
    [Parameter(Mandatory = $true)]
    [string]$RepoBasePath,
    # Use to switch to Snapshot version of repository
    [Parameter()]
    [switch]$SnapshotVersions,
    # Runs the tasks in parallel
    [Parameter()]
    [switch]$Parallel,
    # If the TestMode is provided the actual versions won't be set
    [Parameter()]
    [switch]$TestMode
)

if (!(Test-Path $RepoListPath)) {
    Write-Error "'RepoListPath' is not a valid path to config file with repository names"
}
if (!(Test-Path $RepoBasePath)) {
    Write-Error "'RepoBasePath' is not a valid path"
}

$RepoBasePath = (Resolve-Path $RepoBasePath)
$startingDir = Get-Location

# determine full repository paths
$repoPaths = @()
$repoPaths = (Get-Content $RepoListPath) | % { 
    if ($_.StartsWith("#")) {
        return;
    }
    return "$RepoBasePath\$_" 
}

# collect repositories whose version actually needs setting
$versionsToSet = @()
Write-Host "Detecting Versions..." -ForegroundColor Yellow
Write-Host "---------------------------------"

$repoPaths | % {

    Set-Location $_

    Write-Host -ForegroundColor Green "Processing Repo '$(Split-Path -Leaf $_)'"

    # check pom file existence
    if (!(Test-Path "$_/pom.xml")) {
        Write-Host -ForegroundColor Yellow " No pom.xml file found at path: $_"
        return
    }
    # read pom.file to get current version
    [xml]$pomFile = Get-Content -Path "$_/pom.xml"

    Write-Host "    Version $($pomFile.project.version) detected"
    
    if ($SnapshotVersions) {
        if ($pomFile.project.version.Contains("SNAPSHOT")) {
            Write-Host -ForegroundColor Yellow "    Repo is already in Snapshot version"
            return
        }
        if ($TestMode) {
            Write-Host "    Setting version to $($pomFile.project.version)-SNAPSHOT"
        }
        else {
            $versionsToSet += @{path = $_; newVersion = "$($pomFile.project.version)-SNAPSHOT" }
        }
    }
    else {
        if (!$pomFile.project.version.Contains("SNAPSHOT")) {
            Write-Host -ForegroundColor Yellow "    Repo is already in Productive version"
            return
        }
        $withoutSnapshot = $pomFile.project.version.split("-SNAPSHOT")[0];
        if ($TestMode) {
            Write-Host "    Setting version to $withoutSnapshot"
        }
        else {
            $versionsToSet += @{path = $_; newVersion = $withoutSnapshot }
        }
    }
}

if ($versionsToSet.Count -gt 0) {
    Write-Host
    Write-Host "Starting repository processing..." -ForegroundColor Yellow
    Write-Host "---------------------------------"
    if ($Parallel) {
        $versionsToSet | % {
            $JobBlock = {
                param($RepoPath, $NewVersion)
                
                Set-Location $RepoPath
                
                $RepoName = $(Split-Path -Leaf $RepoPath);
                
                Write-Host "Setting version to $NewVersion for Repository '$RepoName'..."
                mvn tycho-versions:set-version -DnewVersion="$NewVersion" -q
                Write-Host -ForegroundColor Green "Finished version switch for Repository $RepoName"
            }
            $jobs = @()
            $jobName = "tycho_versions_set_$($_)"
            Start-Job -ScriptBlock $JobBlock -ArgumentList $_.path, $_.newVersion -Name $jobName
            $jobs += $jobName
        }
        Receive-Job -Name $jobs -Wait -AutoRemoveJob
    }
    else {
        $versionsToSet | % {
            $RepoPath = $_.path
            $NewVersion = $_.newVersion

            Set-Location $RepoPath
                
            $RepoName = $(Split-Path -Leaf $RepoPath);
                
            Write-Host "Setting version to $NewVersion for Repository '$RepoName'..."
            mvn tycho-versions:set-version -DnewVersion="$NewVersion" -q
            Write-Host -ForegroundColor Green "Finished version switch for Repository $RepoName"
        }
    }
}

Set-Location $startingDir