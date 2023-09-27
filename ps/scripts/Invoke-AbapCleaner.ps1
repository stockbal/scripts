<#
.SYNOPSIS
    Can be used to execute the abap-cleaner cli in bulk
.DESCRIPTION
    Can be used to execute the abap-cleaner cli in bulk
    Required Environement Variables:
    - ABAPCleanerProfile - Must point to concrete .cfj profile file for the ABAP Cleaner
    - ABAPCleanerStandalone - Must point to folder where the ABAP Cleaner standalone .exe is located
#>
param(
    # Working directory (location of abapGit repository) - defaults to the current directory
    [Parameter()]
    [string]$WorkingDir,
    # Optional - list of files to be formatted
    [Parameter()]
    [string[]]$Files,
    # Optional - Git commit to use as file source
    [Parameter()]
    [string]$CommitHash,
    # ABAP Release restriction
    [Parameter()]
    [string]$Release
)

if ($WorkingDir -eq "") {
    $WorkingDir = "."
} 

if (!($null -eq $files)) {
    $abapFiles = $files | ForEach-Object { Resolve-Path $_ } | Where-Object { $_.Path.EndsWith(".abap") }
    if ($null -eq $abapFiles) {
        Write-Host "No relevant ABAP files found" -ForegroundColor Yellow
        return
    }
}

if ($null -eq $abapFiles -and !("" -eq $CommitHash) -and !($WorkingDir -eq "")) {
    $currentLocation = Get-Location
    Set-Location $WorkingDir
    $abapFiles = (git diff-tree --no-commit-id --name-only $CommitHash -r 2>&1)
    Set-Location $currentLocation
    if ($null -eq $abapFiles -or $abapFiles.count -eq 0 -or ($abapFiles[0].GetType().Name -eq ("ErrorRecord")) ) {
        write-host "No Files in Commit $CommitHash or not a valid commit" -ForegroundColor Yellow
        return
    }
    else {
        $abapFiles = $abapFiles | Where-Object { $_.EndsWith(".abap") } | ForEach-Object { Resolve-Path $WorkingDir/$_ }
    }
}

if ($null -eq $abapFiles) {
    $abapFiles = (Get-ChildItem (Resolve-Path $WorkingDir/src/) -Filter "*.abap" -Recurse) | ForEach-Object { $_.FullName }
}

$fileCount = $abapFiles.Count

# Check if environment variables are correctly set
if ($null -eq $env:ABAPCleanerProfile -or !(Test-Path $env:ABAPCleanerProfile) -or !($env:ABAPCleanerProfile).EndsWith(".cfj")) {
    Write-Warning "ABAP-Cleaner profile not set in Environment variable 'ABAPCleanerProfile'. Default settings are used!"
}
else {
    $cleanerProfile = $env:ABAPCleanerProfile
}

if ($null -eq $env:ABAPCleanerStandalone) {
    Write-Error "Environment variable 'ABAPCleanerStandalone' is not set"
}

if (!(Test-Path $env:ABAPCleanerStandalone/abap-cleanerc.exe)) {
    Write-Error "abap-cleanerc.exe not located at $env:ABAPCleanerStandalone"
    return
}

$i = 0

Write-Host -ForegroundColor Yellow "$fileCount ABAP files to be formatted with ABAP Cleaner"

$abapFiles | ForEach-Object {
    $i++

    Write-Host "Processing File '$(Resolve-Path -Relative $_)' ($i of $fileCount)"

    $cleanerArgs = @();
    $cleanerArgs += "--sourcefile", $_, "--targetfile", $_, "--overwrite"
    
    if (!($Release -eq "")) {
        $cleanerArgs += "--release", $Release
    }
    if (!($null -eq $cleanerProfile)) {
        $cleanerArgs += "--profile", $cleanerProfile
    } 

    $formattingError = (& $env:ABAPCleanerStandalone/abap-cleanerc.exe $cleanerArgs)

    if (!($null -eq $formattingError) -and $formattingError[0].StartsWith("Parse error")) {
        Write-Host " > Error during processing. File could not be formatted/cleaned!" -ForegroundColor Red
        Write-Host " > Reason: $($formattingError[0])" -ForegroundColor Red
        return
    }
    else {
        # NOTE: re-write content to add missing line-feed at end of file
        Set-Content -Value "$(Get-Content $_ -Raw)" $_
    }
}

Write-Host -ForegroundColor Green "Formatting completed!"