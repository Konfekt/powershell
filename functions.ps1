# # Truncate homedir to ~
# function limit-HomeDirectory($Path) {
#   $Path.Replace("$home", "~")
# }

# # Must be called 'prompt' to be used by pwsh
# # https://github.com/gummesson/kapow/blob/master/themes/bashlet.ps1
# function prompt {
#   $realLASTEXITCODE = $LASTEXITCODE
#   Write-Host $(limit-HomeDirectory("$pwd")) -ForegroundColor Yellow -NoNewline
#   Write-Host " $" -NoNewline
#   $global:LASTEXITCODE = $realLASTEXITCODE
#   Return " "
# }

# Use 'less.exe' instead of 'less' to bypass less() from PSCX
# function l($dir) {Get-ChildItem -Path $dir -Name | Out-Host -paging}
if (Get-Command "less.exe" -ErrorAction 'Ignore') {
	function l($dir) {Get-ChildItem -Path $dir | Format-Wide Name -AutoSize | less.exe}
	function ll($dir) {Get-ChildItem -Path $dir | less.exe}
	# function P($file)    {$ErrorActionPreference = "SilentlyContinue"; Get-Content $file | Out-Host -paging}
	Set-Alias P less.exe
} else {
	function l($dir) {Get-ChildItem -Path $dir | Format-Wide Name -AutoSize | Out-Host -paging}
	function ll($dir) {Get-ChildItem -Path $dir | Out-Host -paging}
	function P    {Out-Host -paging}
	function P($file)    {$ErrorActionPreference = "SilentlyContinue"; Get-Content $file | Out-Host -paging}
}

function New-Directory($dir) { New-Item -Name $dir -ItemType "directory" }
Set-Alias -Option AllScope -Name md -Value New-Directory
function New-Change-Directory($dir) { New-Item -Name $dir -ItemType "directory" && Set-Location -Path $dir }
Set-Alias mcd New-Change-Directory

# From https://stackoverflow.com/questions/34559553/create-a-temporary-directory-in-powershell
function New-TemporaryDirectory {
	$tempFolderPath = Join-Path $Env:Temp $(New-Guid)
	New-Item -Type Directory -Path $tempFolderPath | Out-Null
  return $tempFolderPath
  # $parent = [System.IO.Path]::GetTempPath()
  # do {
  #   $name = [System.IO.Path]::GetRandomFileName()
  #   $item = New-Item -Path $parent -Name $name -ItemType "directory" -ErrorAction SilentlyContinue
  # } while (-not $item)
  # return $item.FullName
}
Set-Alias mktemp Change-TemporaryDirectory
function Change-TemporaryDirectory() {
	Set-Location -Path $(New-TemporaryDirectory)
}
Set-Alias cdt Change-TemporaryDirectory

# Set-Alias ii invoke-item
# Set-Alias open Invoke-Item
if ($IsWindows) {
  Function open($path)      {Start-Process $path}
# Function o(path) {Start-Process $path -NoNewWindow -WindowStyle Minimized}
} else {
  Function open($path)      {Start-Process nohup "pwsh -noprofile -c "$path""}
}
Set-Alias o    Invoke-Item
Function  oo  {Invoke-Item "$(Get-Location)"}

if (-Not (Get-Command "grep.exe" -ErrorAction 'Ignore')) {
  function grep($regex, $dir) {
	  if ( $dir ) {
		  get-childitem $dir | select-string $regex
		  return
	  }
	  $input | select-string $regex
  }
  function grep-v($regex) {
	  $input | where-object { !$_.Contains($regex) }
  }
}

if     (Get-Command "rg" -ErrorAction 'Ignore') {
  if (Get-Command "less.exe" -ErrorAction 'Ignore') {
    function s() { rg --pretty --smart-case $args | less.exe -Q -iRXF }
  } else {
    function s() {rg --pretty --smart-case $args | Out-Host -paging }
  }
} elseif (Get-Command "ag" -ErrorAction 'Ignore') {
  if (Get-Command "less.exe" -ErrorAction 'Ignore') {
    function s() { ag --color --heading --numbers --smart-case $args | less.exe -Q -iRXF }
  } else {
    function s() { ag --color --heading --numbers --smart-case $args | Out-Host -paging }
  }
# } elseif (Get-Command "grep" -ErrorAction 'Ignore') {
} else   {
  if (Get-Command "less.exe" -ErrorAction 'Ignore') {
    function s() { grep $args | less.exe -Q -iRXF }
  } else {
    function s() { grep $args | Out-Host -paging }
  }
}

