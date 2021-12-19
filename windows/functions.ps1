function uptime {
  Get-CimInstance Win32_OperatingSystem | select-object csname, @{LABEL='LastBootUpTime';
  EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
}

function reboot {
  shutdown /r /t 0
}

function pkill($name) {
  get-process $name -ErrorAction SilentlyContinue | stop-process
}

function pgrep($name) {
  get-process $name
}

# From https://stackoverflow.com/questions/894430/creating-hard-and-soft-links-using-powershell
# function ln-s($link, $target) { New-Item -ItemType SymbolicLink -Path $link -Target $target }
function ln-s() { param($target, $link = (Split-Path $target -Leaf)); New-Item -ItemType HardLink -Path $link -Value $target }
function ln-s() { param($target, $link = (Split-Path $target -Leaf)); New-Item -ItemType SymbolicLink -Path $link -Value $target }
# function ln-s ($link, $target) {
#     if ($PSVersionTable.PSVersion.Major -ge 5) {
#         New-Item -Path $link -ItemType SymbolicLink -Value $target
#     }
#     else {
#         $command = "cmd /c mklink /d"
#         invoke-expression "$command ""$link"" ""$target"""
#     }
# }

# Below functions are taken from
# https://github.com/mikemaccana/powershell-profile/blob/master/unix.ps1

# http://stackoverflow.com/questions/39148304/fuser-equivalent-in-powershell/39148540#39148540
function fuser($relativeFile){
  $file = Resolve-Path $relativeFile
  write-output "Looking for processes using $file"
  foreach ( $Process in (Get-Process)) {
    foreach ( $Module in $Process.Modules) {
      if ( $Module.FileName -like "$file*" ) {
        $Process | select-object id, path
      }
    }
  }
}

function df {
  get-volume
}

function which($name) {
  Get-Command $name | Select-Object -ExpandProperty Definition
}

function cut(){
  foreach ($part in $input) {
    $line = $part.ToString();
    $MaxLength = [System.Math]::Min(200, $line.Length)
    $line.subString(0, $MaxLength)
  }
}

function Private:file($file) {
  $extension = (Get-Item $file).Extension
  $fileType = (get-itemproperty "Registry::HKEY_Classes_root\$extension")."(default)"
  $description =  (get-itemproperty "Registry::HKEY_Classes_root\$fileType")."(default)"
  write-output $description
}

# From https://github.com/Pscx/Pscx
function sudo(){
  Invoke-Elevated @args
}

function find-file($name) {
  get-childitem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | foreach-object {
    write-output = $PSItem.FullName
  }
}

# set-alias find find-file

$path = "$env:COMMANDER_PATH"
if (-Not (Test-Path $path -ErrorAction 'Ignore')) {
  $path = Get-ItemPropertyValue 'HKEY_CURRENT_USER\Software\Ghisler\Total Commander' 'InstallDir' -ErrorAction 'Ignore'
  if (-Not (Test-Path $path -ErrorAction 'Ignore')) {
    $path = Get-ItemPropertyValue 'HKEY_LOCAL_MACHINE\Software\Ghisler\Total Commander' 'InstallDir' -ErrorAction 'Ignore'
  }
}
if (Test-Path "$path/totalcmd64.exe" -ErrorAction 'Ignore') {
  Function oo    {Start-Process $path/totalcmd64.exe -ArgumentList "/O /T /R=`"$(Get-Location)`""}
#   Function  oo  {& "$env:commander_path\totalcmd64.exe" /O /T /R="$(Get-Location)"}
} elseif (Test-Path "$path/totalcmd.exe" -ErrorAction 'Ignore') {
  Function oo    {Start-Process $path/totalcmd64.exe -ArgumentList "/O /T /R=`"$(Get-Location)`""}
}

if (Test-Path "$env:ProgramFiles\git\usr\bin\tig.exe") {
  function tig() {
    [CmdletBinding()] Param()
    $cwd = "$(Get-Location)"
    Push-Location "$env:ProgramFiles\Git\usr\bin"
      & .\tig.exe -C "$cwd" "$(($MyInvocation).UnboundArguments)"
    Pop-Location
  }
}
