Function Get-FolderSizes() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FolderName
    )
    $Files = @()
    $FileCount = (gci -Path $args[0]).Count
    $AllFilesLength = 0
    if ($FileCount -eq 0) {
        "Folder $args[0] does not contain any files/folder"
        return
    }
    # Start size determination
    $i = 0;
    gci -force $FolderName -ErrorAction SilentlyContinue | ? { $_ -is [io.directoryinfo] } | % { 
        $i++
        $percentComplete = $i / $FileCount * 100
        $percentText = '{0:N1}' -f $percentComplete
	    Write-Progress -Activity "Determining Folder/File Sizes" -Status "$percentText% Complete" -PercentComplete $percentComplete;
	    $len = 0
	    gci -recurse -force $_.fullname -ErrorAction SilentlyContinue | % { $len += $_.length }
        $AllFilesLength += $len
	    $Row = "" | Select Name, Size, SizeInt
	    $Row.Name = $_.Name
	    #$Row.Size = 
        $Row.SizeInt = $len / 1Mb
        $Row.Size = '{0:N2} MB' -f $Row.SizeInt
	    $Files += $Row
    }

    $Files | Sort-Object -Property SizeInt | FT Name, Size
    write "-------------------------------------------------"
    write "Size of all files/folder:", ('{0:N2} MB' -f ($AllFilesLength / 1Mb))
}