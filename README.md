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

- **Add-FilesToGitRepos**  
  Adds a list of files to 1 ore more git repositories whose URLs are defined in simple text file. For a complete list of parameters enter `Get-Help Add-FilesToGitRepos` in a `PowerShell` instance
- **Set-PlugInVersions**  
  Changes the version of an Eclipse Plug-In project in all available metadata files (i.e. `manifest.mf`, `features.xml`, `pom.xml`).  
  **Note**: The version change itself is performed with maven tycho, and therefore requires that the plug-in project is setup with maven (i.e. root folder needs a `pom.xml`-file)

## List of available cmdlets/functions

### Module 'Folder-Scripts'

- Get-FolderSizes  
  Determines the sizes of direct child folders of a given folder

### Module 'UI5'  

- Copy-UI5Translations  
  Copies i18n folder (+ sub folders) of a UI5 App/Library to a given target folder
- Test-I18nKeysUsage  
  Checks the usage of the keys in all i18n translation files of a given App/Library folder  

### Module 'Git'

- Reset-GitLocal  
  Resets local changes of a single or multiple git repositories
- Invoke-CloneGitRepos  
  Clones git repositories from given list of git URLs  
- New-GitRemoteBranch  
  Create new remote branch in a list of git repositories

## Examples calls

### New-GitRemoteBranch

Create new remote branches for a list of git repositories.  
The repository URLs are supplied via a text file

```powershell
> New-GitRemoteBranch -URL (cat ~\repos.txt) -BaseBranch master -TargetBranch release_new -WorkingDir temp
```

Create new remote branches for a specific git repository that already exists on the pc

```powershell
> New-GitRemoteBranch -Path .\repository -BaseBranch master -TargetBranch release_new
```
