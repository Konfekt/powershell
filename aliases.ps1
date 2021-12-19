Set-Alias e     vim

Set-Alias ge    gvim
Set-Alias g     git

if (Get-Command "peco" -ErrorAction 'Ignore') {
  Set-Alias F     peco
} elseif (Get-Command "fzf" -ErrorAction 'Ignore') {
  Set-Alias F     fzf
}

if     (Get-Command "ssdiff" -ErrorAction 'Ignore') {
  Set-Alias xlsdiff ssdiff
  Set-Alias sscat   xlsdiff
}

if (Get-Command "lazygit" -ErrorAction 'Ignore') {
Set-Alias lzg   lazygit
}

if (Get-Command "mmv" -ErrorAction 'Ignore') {
  Function rnn     {mmv *}
  Set-Alias rn      mmv
}
if (Get-Command "lf" -ErrorAction 'Ignore') {
Function  rr    {lf "$pwd"}
Set-Alias r     lf
}

# Enhances the built-in Measure-Command by supporting
#
# - multiple commands whose timings can be compared.
# - averaging the timings of multiple runs per command.
# - passing input objects via the pipeline that the commands see
#   as the entire collection in variable $_
# - printing command output to the console for diagnostic purposes.
#
# . $PSProfileFolder/custom/Time-Command.ps1 4>$null
# Set-Alias tc    Time-Command

# 4>$null.ps1 to mute installation instructions;
# see https://gist.github.com/mklement0/880624fd665073bb439dfff5d71da886#gistcomment-3891840
. $PSProfileFolder/custom/Enter-AdminPSSession 4>$null.ps1
  Set-Alias eap Enter-AdminPSSession

  . $PSProfileFolder/custom/Show-Help.ps1 4>$null
# Get Help Online
  Set-Alias gho    Show-Help

# # Like Unix touch, creates new files and updates time on old ones
# # PSCX has a touch, but it doesn't make empty files
# function Touch-File($file) {
# 	if ( Test-Path $file ) {
# 		Set-FileTime $file
# 	} else {
# 		New-Item $file -type file
# 	}
# }
. $PSProfileFolder/custom/Touch-File.ps1 4>$null
  if ($IsWindows) {
    Set-Alias touch Touch-File
  }

Function gh($cmd)    {$ErrorActionPreference = "SilentlyContinue"; Get-Help -Full $cmd | Out-Host -paging}

Function ..    {Set-Location -Path ..}
Function ...    {Set-Location -Path ../..}
Function ....    {Set-Location -Path ../../..}
Function .....    {Set-Location -Path ../../../..}

Function rs($source,$dest)    {rsync --info=stats1,progress2 --human-readable --compress --archive --one-file-system --executability --hard-links --acls --modify-window=1 --update --delete $source $dest}
Function rs-cp($source,$dest) {rsync --info=stats1,progress2 --human-readable --compress --archive --one-file-system --executability --hard-links --acls --modify-window=1 $source $dest}
Function rs-mv($source,$dest) {rsync --info=stats1,progress2 --human-readable --compress --archive --one-file-system --executability --hard-links --acls --modify-window=1 --remove-source-files $source $dest}
