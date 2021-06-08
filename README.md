# scripts

Holds scripts for day to day use

## Using the included scripts
1) Clone this repository  
2) Add the path to the `scripts` folder of the cloned repository to your `PATH` variable  
3) Test the correctness of the `PATH` in new PowerShell instance  
   ```powershell
   $env:PATH
   ```
   The output should include the specified path und you should now be able to call the scripts


## Using the included cmdlets (i.e. PowerShell functions)
1) Clone this repository
2) Open up a new `PowerShell` instance
3) Enter the following command
   ```powershell
   notepad $PROFILE
   ```
4) In the opened text file import a single module from the `module`-folder via the following command
   ```powershell
   # Module imports
   Import-Module "<Path-to-the-cloned-repo>\modules\<module-file-name>.psm1"
   ```
5) Save the file and restart the `PowerShell`. You should now be able to call any included cmdlet/function
## List of available scripts

- Add-FilesToGitRepos   
  Adds a list of files to 1 ore more git repositories whose URLs are defined in simple text file. For a complete list of parameters enter `Get-Help Add-FilesToGitRepos` in a `PowerShell` instance

## List of available cmdlets/functions
- Get-FolderSizes  
  Determines the sizes of direct child folders of a given folder
- Copy-UI5Translations  
  Copies i18n folder (+ sub folders) of a UI5 App/Library to a given target folder
- Test-I18nKeysUsage  
  Checks the usage of the keys in all i18n translation files of a given App/Library folder