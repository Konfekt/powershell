$PSProfileFolder = Split-Path -Path $PROFILE

# Get-ChildItem -Path $PSProfileFolder -Filter "*.ps1" | ForEach-Object {
#   . $_.FullName
# }

. $PSProfileFolder\modules.ps1
# To update all modules, run:
# . $PSProfileFolder\custom\Update-AllPowerShellModules.ps1
. $PSProfileFolder\exports.ps1
. $PSProfileFolder\functions.ps1
. $PSProfileFolder\aliases.ps1

if ($IsLinux) {
  # $pathSeparator = ":"
  Get-ChildItem -Path $PSProfileFolder\linux -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
  }
  . $PSProfileFolder/custom/Set-SolarizedLightColorDefaults.ps1
}
elseif ($IsMacOS) {
  # $pathSeparator = ":"
  Get-ChildItem -Path $PSProfileFolder\macos -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
  }
  . $PSProfileFolder/custom/Set-SolarizedLightColorDefaults.ps1
}
else {
  # if ($IsWindows)
  # $pathSeparator = ";"
  Get-ChildItem -Path $PSProfileFolder\windows -Filter "*.ps1"| ForEach-Object {
    . $_.FullName
  }

  # Chocolatey profile
  $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
  if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
  }

  . (Join-Path -Path (Split-Path -Parent -Path $PROFILE) -ChildPath "\custom\$(switch($HOST.UI.RawUI.BackgroundColor.ToString()){'White'{'Set-SolarizedLightColorDefaults.ps1'}'Black'{'Set-SolarizedDarkColorDefaults.ps1'}default{return}})")
}

