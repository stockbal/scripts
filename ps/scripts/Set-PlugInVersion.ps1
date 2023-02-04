<#
.SYNOPSIS
    Sets version of plug-in project with maven tycho plug-in
#>
param(
    # Path to .txt file with paths to git repositories
    [Parameter(Mandatory = $true)]
    [string]$RepoPath,
    # Flag to indicate the version should not be a SNAPSHOT version
    [Parameter()]
    [switch]$MakeRelease,
    # Fully specified version, e.g. 1.1.5
    [Parameter()]
    [string]$NewVersion,
    # Flag to indicate Patch
    [Parameter()]
    [switch]$PatchUpdate,
    # Flag to indicate Minor update
    [Parameter()]
    [switch]$MinorUpdate,
    # Flag to indicate Major update
    [Parameter()]
    [switch]$MajorUpdate,
    # If the TestMode is provided, only the commit to the repositories will be done
    # but no push will occur. The repositories will still exist after the script
    # has run its course
    [Parameter()]
    [switch]$TestMode
)

if ($TestMode) {
    Write-Host -ForegroundColor Yellow "[--- Test mode ---]"
}

$cwd = Get-Location

Function updatePomVersion([string]$RepoPath,[string]$OldVersion,[string]$NewVersion) {
    Set-Location $RepoPath
    Write-Host "Updating version from $OldVersion to $NewVersion"
    if (!$TestMode) {
        mvn tycho-versions:set-version -DnewVersion="$NewVersion" -q
    }
    Set-Location $cwd
}

if (!(Test-Path $RepoPath)) {
    Write-Error "RepoPath does not exist"
    return
}

if ($NewVersion -and !($NewVersion -match "^\d+\.\d+\.\d+$")) {
    Write-Error "The supplied version $NewVersion is invalid. Use Major.Minor.Patch"
    return
}

$RepoPath = (Resolve-Path $RepoPath)

if (!(Test-Path "$RepoPath\pom.xml")) {
    Write-Error "Folder does not contain a pom.xml file"
    return
}

# read pom.xml file
[xml]$pom = Get-Content -Path "$RepoPath\pom.xml"

$version = $pom.project.version

if ($NewVersion) {
    if (!$MakeRelease) {
        $NewVersion += "-SNAPSHOT"
    }
    if ($NewVersion -eq $version) {
        Write-Host -ForegroundColor Yellow "Version already matches $NewVersion"
        return
    }
    updatePomVersion -RepoPath $RepoPath -OldVersion $version -NewVersion $NewVersion
} else {

    # Determine snapshot part of version
    if ($version.Contains("SNAPSHOT")) {
        $version = $version.Split("-SNAPSHOT")[0]
    }

    # extract all parts of version
    $versionParts = $version.Split(".");
    $majorNumber = [int]$versionParts[0];
    $minorNumber = [int]$versionParts[1];
    $patchNumber = [int]$versionParts[2];

    if ($MajorUpdate) {
        $majorNumber += $majorNumber
        $minorNumber = 0
        $patchNumber = 0
    } else {
        if ($MinorUpdate) {
            $minorNumber += 1
            $patchNumber = 0
        } else {
            if ($PatchUpdate) {
                $patchNumber += 1
            } else {
                Write-Error "Either 'NewVersion', 'MajorUpdate', 'MinorUpdate' oder 'PatchUpdate' must be supplied"
                return

            }
        }
    }

    $NewVersion = "$majorNumber.$minorNumber.$patchNumber"
    if (!$MakeRelease) {
        $NewVersion += "-SNAPSHOT"
    }

    if ($NewVersion -eq $version) {
        Write-Host -ForegroundColor Yellow "Version already matches $NewVersion"
        return
    }

    updatePomVersion -RepoPath $RepoPath -OldVersion $pom.project.version -NewVersion $NewVersion
}