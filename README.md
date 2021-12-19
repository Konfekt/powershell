A Microsoft Windows [Powershell](https://github.com/PowerShell/PowerShell) profile to get the most out of muscle memory from Linux, adding convenience functions to search text in files, sync folders, page output, navigate the file system, operate on the clipboard, ... and much more;
it loads the modules

- [PSReadLine](https://www.powershellgallery.com/packages/PSReadLine) for Readline bindings
- [PSReadLineHistory](https://www.powershellgallery.com/packages/PSReadLineHistory) and lookup of previous commands
- [posh-git](https://www.powershellgallery.com/packages/posh-git) for a Git status prompt
- [PSFzf](https://www.powershellgallery.com/packages/PSFzf) for fuzzy finding files, folders and previous commands
- [z](https://www.powershellgallery.com/packages/z) to jump to frecent (= frequent and recent) directories by typing `z` and a partial match of their path (say `z Doc` to change directory to `%USERPROFILE%\Documents`)
- [PSEverything](https://www.powershellgallery.com/packages/PSEverything) for searching the indexed hard disc
- [Recycle](https://www.powershellgallery.com/packages/Recycle) for sending files to the Recycle bin (instead of deleting them), and
- [pscx](https://www.powershellgallery.com/packages/pscx) for miscellaneous useful commands.

Install it by cloning into `~/.config` and, in Microsoft Windows, additionally linking `%USERPROFILE%\Documents\Microsoft.PowerShell_profile.ps1` to `%USERPROFILE%\.confing\powershell\Microsoft.PowerShell_profile.ps1`

To install all modules, uncomment the lines below in `modules.ps1` (where `$global:modules` is the list of modules `z, PSfzf`, ...), start `powershell` once and remove them (to save start-up time):

```ps1
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Module -Name PowerShellGet -Force
foreach ($module in $global:modules) {
  if (!(Get-Module -ListAvailable | ? { $_.name -like $module })) {
    Install-Module -AllowClobber -AllowPrerelease -Scope CurrentUser $module
  }
}
```

