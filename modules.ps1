$global:modules = @()

# $modulePath = "$PSProfileFolder/custom$pathSeparator"
# $modulePath += [Environment]::GetEnvironmentVariable('PSModulePath')
# [Environment]::SetEnvironmentVariable('PSModulePath', $modulePath)

$global:modules += ("posh-git", "PSReadLine", "PSReadLineHistory", "PSFzf")
# $global:modules += ("cdpath", "pshosts", "TabExpansionPlusPlus", "PowerColorLS")

if ($isWindows) {
  $global:modules += ("PSEverything", "pscx", "Recycle", "z")
# Invoke-Expression (& { (lua $env:XDG_CONFIG_HOME/bin/z.lua --init powershell) -join "`n" })
# or, alternatively,
# git clone https://github.com/JannesMeyer/z.ps.git .../Modules/z

  If ($PSVersionTable.PSEdition -eq "Core") {
    $global:modules += ("WslInterop")
  }
}

# set up connection behind proxy
[net.webrequest]::defaultwebproxy.credentials = [net.credentialcache]::defaultcredentials
# use up-to-date https security protocol
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# # To install all modules, uncomment below lines:
# # See https://gist.github.com/metablaster/52b1baac5be44e2f1e6d16800813f42f#tutorial-steps
# Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
# Install-Module -Name PowerShellGet -Force
# foreach ($module in $global:modules) {
#   if (!(Get-Module -ListAvailable | ? { $_.name -like $module })) {
#     Install-Module -AllowClobber -AllowPrerelease -Scope CurrentUser $module
#   }
# }

foreach ($module in $global:modules) {
  import-module $module
  $moduleSetupFile = $PSProfileFolder+'\settings\'+$module+'.ps1'
  If (Test-Path $moduleSetupFile){
    . $moduleSetupFile
  }
}

If ($PSVersionTable.PSEdition -ne "Core" -And (Test-Path("$PSProfileFolder\custom\posh-cde.psm1"))) {
  import-module "$PSProfileFolder\custom\posh-cde.psm1"
}
