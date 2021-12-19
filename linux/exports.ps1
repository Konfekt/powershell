# global variables and core env variables
$HOME_ROOT = [IO.Path]::GetPathRoot($HOME)

$env:EDITOR = 'vim'
# $env:VISUAL = 'gvim'
if ( $env:BROWSER) {
  $env:BROWSER = $env:BROWSER
} else {
  $env:BROWSER = 'xdg-open'
}

if ($env:PDFVIEWER) {
  $env:PDFVIEWER = $env:PDFVIEWER
} elseif (Get-Command 'zathura' -ErrorAction 'Ignore') {
  $env:PDFVIEWER = 'zathura'
} elseif (Get-Command 'mupdf' -ErrorAction 'Ignore') {
  $env:PDFVIEWER = 'mupdf'
} else {
  $env:PDFVIEWER = 'xdg-open'
}

if (Test-Path($env:XDG_CACHE_HOME) -ErrorAction 'Ignore') {
  [Environment]::SetEnvironmentVariable('Temp', $env:XDG_CACHE_HOME)
} elseif (Test-Path($env:TMPDIR) -ErrorAction 'Ignore') {
  [Environment]::SetEnvironmentVariable('Temp', $env:TMPDIR)
}
