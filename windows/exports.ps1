# # Set the $HOME variable for our use and make powershell recognize ~\ as $HOME in paths
# $env:HOME = (resolve-path $env:userprofile)
# # global variables and core env variables
# $HOME_ROOT = [IO.Path]::GetPathRoot($env:userprofile)

(get-psprovider FileSystem).Home = $env:userprofile
# OS default location needs to be set as well
[System.Environment]::CurrentDirectory = $env:userprofile

# Oddly, Powershell doesn't have an inbuilt variable for the documents directory. So let's make one:
# From https://stackoverflow.com/questions/3492920/is-there-a-system-defined-environment-variable-for-documents-directory
$env:DOCUMENTS = [Environment]::GetFolderPath("mydocuments")

If (Test-Path "${env:ProgramFiles}\Mozilla Firefox"){
  $env:PATH += ";${env:ProgramFiles}\Mozilla Firefox"
}
# $env:PATH += ";${env:ProgramFiles}\Mozilla Thunderbird"

If (Test-Path "${env:ProgramFiles}\Okular\bin"){
  $env:PATH += ";${env:ProgramFiles}\Okular\bin"
}
If (Test-Path "${env:ProgramFiles}\Irfanview"){
  $env:PATH += ";${env:ProgramFiles}\Irfanview"
}

# Unix Utils ...
# ... from Gow
If (Test-Path "${env:ProgramFiles(x86)}\Gow\bin"){
  $env:PATH += ";${env:ProgramFiles(x86)}\Gow\bin"
}
# ... from Git
If (Test-Path "${env:ProgramFiles}\git\bin"){
  $env:PATH += ";${env:ProgramFiles}\git\bin"
}
# # ... but NOT from ...\usr\bin to avoid clobbering find.exe, ... from Windows
# $env:PATH += ";${env:ProgramFiles}\git\usr\bin"

If (Test-Path "${env:ProgramFiles}\LibreOffice\program"){
  $env:PATH += ";${env:ProgramFiles}\LibreOffice\program"
}
If (Test-Path "${env:ProgramFiles(x86)}\Aspell\bin"){
  $env:PATH += ";${env:ProgramFiles(x86)}\Aspell\bin"
}

if (Get-Command 'vim' -ErrorAction 'Ignore') {
  $env:EDITOR = 'vim'
# $env:VISUAL = 'gvim'
} else {
  $env:EDITOR = 'notepad'
}
if (Get-Command 'firefox' -ErrorAction 'Ignore') {
  $env:BROWSER = 'firefox'
} else {
  $env:BROWSER = 'cmd.exe /c start /b'
}
if (Get-Command 'mupdf' -ErrorAction 'Ignore') {
  $env:PDFVIEWER = 'mupdf'
} else {
  $env:PDFVIEWER = 'cmd.exe /c start /b'
}

# See https://stackoverflow.com/questions/370030/why-git-cant-remember-my-passphrase-under-windows/58784438#58784438
# $env:PATH += ";$env:SystemRoot\system32\OpenSSH"
$env:GIT_SSH = "$env:SystemRoot\system32\OpenSSH\ssh.exe"

# XDG
$env:XDG_CONFIG_HOME = "$env:UserProfile/.config"
$env:XDG_DATA_HOME = "$env:UserProfile/.local/share"
$env:XDG_STATE_HOME = "$env:UserProfile/.local/state"
$env:XDG_CACHE_HOME = "$env:UserProfile/.cache"
$env:XDG_DOWNLOAD_DIR = "$env:UserProfile/Downloads"

