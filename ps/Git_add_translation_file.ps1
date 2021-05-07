$root = "C:\Users\stockbal\Documents\Developer\Dairy-ui5-translation"
$repoList = "C:\Users\stockbal\Documents\Developer\Projects\UI5\Dairy\translation-tools\list.txt"
$transFileName = "translation_v2.json"
$translationFile = "C:\Users\stockbal\Documents\Developer\Dairy-ui5-translation\$transFileName"
$branchName = "Development"
(get-content $repoList) | % {
    cd $root
    $repoName = (split-path -Leaf $_)
    write-host -ForegroundColor Yellow "1) Cloning $_"
    git clone $_ --quiet
    cd $root\$repoName
    write-host -ForegroundColor Yellow "2) Checkout branch $branchName"
    git checkout $branchName --quiet
    if (!([string](git symbolic-ref HEAD)).EndsWith($branchName)) {
        Write-Host -ForegroundColor Red "Branch '$branchName' does not exist in Repository '$repoName'"
        Write-Host "-----------------------------------------"
        continue
    }
    Write-Host -ForegroundColor Yellow "3) Adding TEW translation file"
    Copy-Item -Path $translationFile -Destination $root\$repoName
    git add translation_v2.json 2>&1
    git commit -m"chore: add TEW translation config" 2>&1
    Write-Host -ForegroundColor Yellow "4) Pushing changes to remote"
    git push origin 2>&1
    
    cd ..
    remove-item -Recurse -Force $repoName
    Write-Host -ForegroundColor Yellow "Finished $repoName"
    Write-Host "-----------------------------------------------------"
}