# Produce UTF-8 by default
# From https://stackoverflow.com/questions/51933189/character-encoding-utf-8-in-powershell-session
[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# https://technet.microsoft.com/en-us/magazine/hh241048.aspx
$MaximumHistoryCount = 10000;

# Make PowerShell downloading files much faster
$global:ProgressPreference = 'SilentlyContinue'

if ($IsWindows) {
  $env:PATH = "$PSProfileFolder\custom;$env:PATH"
} else {
  $env:PATH = "$PSProfileFolder/custom:$env:PATH"
}

if (Get-Command "less" -ErrorAction 'Ignore') {
  $env:PAGER = 'less'

  $env:LESS = '-Q -iRXF -P%f ?m(file %i/%m) .lines %lt-%lb?L/%L. ?e(END)?x - Next\: %x.:?PB%PB\%..%t'
  $env:LESSEDIT = 'vim -RM ?lm+%lm. %f'
  $env:LESSHISTFILE = "$env:XDG_STATE_HOME/less/history"
  $env:LESSKEY = "$env:XDG_CONFIG_HOME/less/keys"
  $env:LESSCHARSET = 'utf-8'
} else {
  $env:PAGER = 'more'
}

$env:_JAVA_OPTIONS = '-Dfile.encoding=UTF-8 -Dawt.useSystemAAFontSettings=lcd -Dswing.aatext=true -Djdk.gtk.version=2'

$env:PYTHONIOENCODING = 'UTF-8'

$env:RIPGREP_CONFIG_PATH = "$env:XDG_CONFIG_HOME/ripgreprc"

$env:PYTHONSTARTUP = "$env:XDG_CONFIG_HOME/pythonstartup.py"

if (-Not $IsWindows) {
  $env:BETTER_EXCEPTIONS = 1
}

$env:HTML_TIDY="$env:XDG_CONFIG_HOME/htmltidyrc"
