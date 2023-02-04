enum UI5Type {
    App = 1
    Library
}

<# 
    Retrieves the full path of an i18n folder inside the 
    provided path
#> 
Function getI18nFolder() {
    param(
        [Parameter()]
        [string]$Path
    )
    $i18nFolder = @{ 
        IsLib = $false;
        Path  = ""
    }
    if (Test-Path "$Path\webapp") {
        (Get-ChildItem "$Path\webapp" -Recurse) | Foreach-Object {
            if ($_.Name -eq "i18n" -and $_.PSIsContainer) {
                $i18nFolder.Path = $_.FullName
                return
            }
        }
    }
    if (Test-Path "$Path\src") {
        (Get-ChildItem "$Path\src\**\messagebundle*.properties" -Recurse) | Foreach-Object {
            $i18nFolder.IsLib = $true
            $i18nFolder.Path = $_.DirectoryName
            return
        }
    }
    return $i18nFolder
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
    $i18n = getI18nFolder -Path $Path
    if (!$i18n -or !$i18n.Path) {
        Write-Host "i18n folder not found in $Path" -ForegroundColor Red
        return
    }
    
    # Should the target folder be created ?
    if ($CreateTarget) { 
        new-item -ItemType Directory $TargetFolder\$repoName -Force
    }
    # Copy Folder to new path
    if ($i18n) {
        if ($i18n.IsLib) {
            Copy-Item -Path "$($i18n.Path)\messagebundle*.properties" -Recurse -Destination $TargetFolder\$repoName -ErrorAction SilentlyContinue
        }
        else {
            Copy-Item -Path $i18n.Path -Recurse -Destination $TargetFolder\$repoName -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Copies i18n folder + sub folders/items to a given target folder
#>
Function Copy-UI5Translations() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Path,
        [Parameter(Mandatory)]
        [string]$Target,
        [Parameter()]
        [bool]$CreateTarget = $true
    )

    foreach ($pathEntry in $Path) {
        $resolvedPath = Resolve-Path $pathEntry
        if (Test-Path $resolvedPath\package.json) {
            copyI18nFolder -Path $resolvedPath -TargetFolder $Target -CreateTarget $CreateTarget
        }
    }
}

Function checkI18nFilesForKey() {
    param (
        [Parameter()]
        [string[]] $FilePaths,
        [Parameter()]
        [string] $Key,
        [Parameter()]
        [string[]] $CustomPattern,
        [Parameter()]
        [bool] $PrintUsages,
        [Parameter()]
        [bool] $OverridePattern
    )

    if ($CustomPattern -and $OverridePattern) {
        foreach ($pattern in $CustomPattern) {
            $patterns += @(
                $pattern.Replace("{key}", "($Key)")
            )
        }
    }
    else {
        $patterns = @(
            "{{($Key)}}"
            "getText\([`\""']($Key)[`\""']" 
            "{(.*i18n>$Key)}"
        )
        if ($CustomPattern) {
            foreach ($pattern in $CustomPattern) {
                $patterns += @($pattern.Replace("{key}", "($Key)"))
            }
        }
    }
    $usages = (Get-ChildItem -Path $FilePaths | Select-String -Pattern $patterns -CaseSensitive -AllMatches )
    if ($usages -and $PrintUsages) {
        Write-Host "Usages of key '$Key'"
        if ($usages.GetType().BaseType.Name -eq "Array") {
            foreach ($match in $usages) {
                Write-Host " > Path: $($match.Path)"
                Write-Host " > Line-No.: $($match.LineNumber)"
                Write-Host " > Line: " -NoNewline
                Write-Host "$($match.Line)" -ForegroundColor Green
                Write-Host                
            }
        }
        else {
            Write-Host " > Path: $($usages.Path)"
            Write-Host " > Line-No.: $($usages.LineNumber)"
            Write-Host " > Line: " -NoNewline
            Write-Host "$($usages.Line)" -ForegroundColor Green
        }
        Write-Host
    }
    if ($usages) {
        return $true
    } 
    return $false
}


<#
.SYNOPSIS
    Tests the i18n key usage of a App or a Library
.DESCRIPTION
    Each key is tested via the following patterns:
    - {{($Key)}}
    - getText\([`\""']($Key)[`\""']
    - {(.*i18n>$Key)}

    Via the parameter -CustomPattern it is possible to add custom patterns to the default ones.
    The pattern must be a valid pattern for CmdLet 'Select-String' and must contain the 
    string {key} which will be replaced with an actual key from a i18n file
#>
Function Test-I18nKeysUsage() {
    [CmdletBinding()]
    param(
        # Path of a UI5 app/library folder
        [Parameter(Mandatory = $true)]
        [string] $Path,
        # Type of the repository (i.e. App or Library)
        [Parameter()]
        [UI5Type] $RepoType = [UI5Type]::App,
        # Custom pattern for key usage search
        [Parameter()]
        [string[]] $CustomPattern,
        # If supplied only the custom pattern are used and therefore must
        # be supplied
        [Parameter()]
        [switch] $OnlyCustomPatterns,
        # If Specified the usages of i18n keys are printed to the console
        [Parameter()]
        [switch] $PrintUsages,
        # If Specified missing key usages will not be printed to the console
        [Parameter()]
        [switch] $NoPrintMissingUsages
    )

    if ($OnlyCustomPatterns -and !$CustomPattern) {
        Write-Error "No value for parameter -CustomPattern specified"
        return
    }

    # Resolve the final path
    $Path = Resolve-Path $Path

    if ($RepoType -eq [UI5Type]::App) {
        $i18nDefaultFilePaths = Get-ChildItem -Path "$Path\webapp\" -Filter i18n.properties -Recurse | ForEach-Object { $_.FullName }
        $relevantFilesPath = "$Path\webapp\"
    }
    else {
        $i18nDefaultFilePaths = Get-ChildItem -Path "$Path\src\" -Filter messagebundle.properties -Recurse | ForEach-Object { $_.FullName }
        $relevantFilesPath = "$Path\src"
    }

    # Determine relevant files for processing 
    $relevantFilesPath = Get-ChildItem $relevantFilesPath -Include *.js, *.xml, *.html, *.json -Recurse | ForEach-Object { $_.FullName }
    
    # Process each default file (the default file should hold all relevant keys)
    foreach ($i18nFilePath in $i18nDefaultFilePaths) {
        # $keyUsages = New-Object System.Collections.Generic.Dictionary"[String,Boolean]"

        Write-Host "Processing file $i18nFilePath"
        $usages = 0
        $keys = 0
        (Get-Content -Path $i18nFilePath) | ForEach-Object {
            $line = $_.Trim()
            
            if (!$line.StartsWith("#") -and $line -ne "") {
                $keyValue = $line.Split("=")
                
                if ($keyValue -and $keyValue.Count -ge 1) {
                    $keys++
                    $newKey = $keyValue[0].Trim()
                    $found = (checkI18nFilesForKey -FilePaths $relevantFilesPath -Key $newKey -CustomPattern $CustomPattern -PrintUsages $PrintUsages -OverridePattern $OnlyCustomPatterns)
            
                    if (!$found) {
                        if (!$NoPrintMissingUsages) {
                            Write-Host "Key " -ForegroundColor Yellow -NoNewline
                            Write-Host $newKey -NoNewline
                            Write-Host " is never used!" -ForegroundColor Yellow
                        }
                    }
                    else {
                        $usages++
                    }
                }
            }
        }
        if ($usages -eq $keys) {
            Write-Host "All $keys keys are used" -ForegroundColor Green
        }
        else {
            Write-Host "$($keys - $usages) Keys are not used" -ForegroundColor Red
        }
        
        Write-Host
        
    }
    

}

Export-ModuleMember *-*