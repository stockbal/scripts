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
if ($null -eq $env:ABAPCleanerProfile) {
    Write-Error "Environment variable 'ABAPCleanerProfile' is not set"
    return
}

if (!(Test-Path $env:ABAPCleanerProfile) -or !($env:ABAPCleanerProfile).EndsWith(".cfj")) {
    Write-Error "Environment variable 'ABAPCleanerProfile' does not point to a valid .cfj file"
    return
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
    
    if (!($Release -eq "")) {
        $formattingError = (& $env:ABAPCleanerStandalone/abap-cleanerc.exe --sourcefile $_ --targetfile $_ --overwrite --release $Release --profile $env:ABAPCleanerProfile)
    }
    else {
        $formattingError = (& $env:ABAPCleanerStandalone/abap-cleanerc.exe --sourcefile $_ --targetfile $_ --overwrite --profile $env:ABAPCleanerProfile)
    }
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