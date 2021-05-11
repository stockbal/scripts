<#
.SYNOPSIS
    Determination of folder sizes in a given folder
.DESCRIPTION
    Determination of the sizes of the direct sub folders
    of a given folder
#>
Function Get-FolderSizes() {
    [CmdletBinding()]
    param(
        # Path to folder
        [Parameter(Mandatory)]
        [string]$FolderPath
    )
    $Files = @()
    $FileCount = (Get-ChildItem -Path $FolderPath).Count
    $AllFilesLength = 0
    if ($FileCount -eq 0) {
        Write-Output "Folder $FolderPath does not contain any files/folder"
        return
    }
    # Start size determination
    $i = 0;
    Get-ChildItem -force $FolderPath -ErrorAction SilentlyContinue | Where-Object { $_ -is [io.directoryinfo] } | ForEach-Object { 
        $i++
        $percentComplete = $i / $FileCount * 100
        $percentText = '{0:N1}' -f $percentComplete
        Write-Progress -Activity "Determining Folder/File Sizes" -Status "$percentText% Complete" -PercentComplete $percentComplete;
        $len = 0
        Get-ChildItem -recurse -force $_.fullname -ErrorAction SilentlyContinue | ForEach-Object { $len += $_.length }
        $AllFilesLength += $len
        $Row = "" | Select-Object Name, Size, SizeInt
        $Row.Name = $_.Name
        #$Row.Size = 
        $Row.SizeInt = $len / 1Mb
        $Row.Size = '{0:N2} MB' -f $Row.SizeInt
        $Files += $Row
    }

    $Files | Sort-Object -Property SizeInt | Format-Table Name, Size
    Write-Output "-------------------------------------------------"
    Write-Output "Size of all files/folder:", ('{0:N2} MB' -f ($AllFilesLength / 1Mb))
}