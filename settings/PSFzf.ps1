if (-Not (Get-Command "fzf" -ErrorAction 'Ignore')) {
  Return
}

# replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r' -TabExpansion

if ($IsWindows) {
  # Set-Alias fz    Invoke-FuzzyZLocation       # Starts fzf with input from the history of ZLocation and sets the current location.
  Set-Alias cde   Set-LocationFuzzyEverything # Sets the current location based on the Everything database.
}

Set-Alias fe    Invoke-FuzzyEdit
Set-Alias ff    Invoke-FuzzySetLocation     # Sets the current location from the user's selection in fzf.
Set-Alias fh    Invoke-FuzzyHistory         # Rerun a previous command from history based on the user's selection in fzf.
Set-Alias fgs   Invoke-FuzzyGitStatus       # Starts fzf with input from output of the git status function.
Set-Alias fkill Invoke-FuzzyKillProcess     # Runs Stop-Process on processes selected by the user in fzf.

# # After "**" and pressing Tab, PsFzf provides list of options
# FZF_COMPLETION_TRIGGER = "**"
# Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

If (Get-Command "fd.exe" -ErrorAction 'Ignore') {
	$DEFAULT_COMMAND="fd --type file --hidden --no-ignore --exclude .git/ --color never --fixed-strings"
} ElseIf (Get-Command "rg.exe" -ErrorAction 'Ignore') {
	$DEFAULT_COMMAND="rg --files --hidden --no-ignore --iglob !.git/ --color never"
} ElseIf (Get-Command "ag.exe" -ErrorAction 'Ignore') {
	$DEFAULT_COMMAND="ag --files-with-matches --unrestricted --ignore .git/ --nocolor --silent"
} Else {
	$DEFAULT_COMMAND="git ls-tree -r --name-only HEAD || pwsh -NoLogo -NoProfile -Noninteractive -Command 'Get-ChildItem -File -Recurse -Name'"
}
# $env:FZF_DEFAULT_COMMAND = $DEFAULT_COMMAND
$env:FZF_CTRL_T_COMMAND  = $env:FZF_DEFAULT_COMMAND

# See https://github.com/kelleyma49/PSFzf/issues/87
If (Get-Command "fd" -ErrorAction 'Ignore') {
	$DEFAULT_DIR_COMMAND="fd --type directory --hidden --no-ignore --exclude .git/ --color never --fixed-strings"
} Else {
	$DEFAULT_DIR_COMMAND = "pwsh -NoLogo -NoProfile -Noninteractive -Command 'Get-ChildItem Directory -Recurse -Name'"
  if ((Get-Command "sed" -ErrorAction 'Ignore') -And (Get-Command "sed" -ErrorAction 'uniq')) {
	  $DEFAULT_DIR_COMMAND = "git ls-files | sed 's,/[^/]*$,,' | uniq || $DEFAULT_DIR_COMMAND"
	}
}
$env:FZF_ALT_C_COMMAND = $DEFAULT_DIR_COMMAND

$env:FZF_DEFAULT_OPTS="--info=inline --keep-right"
	# `--exact` makes single quotes '...'  look for exact match of ...
  # this option needs to be removed in Vim
$env:FZF_DEFAULT_OPTS="$env:FZF_DEFAULT_OPTS --exact"
$env:FZF_DEFAULT_OPTS="$env:FZF_DEFAULT_OPTS --bind=ctrl-l:accept,ctrl-u:kill-line,change:top,alt-j:preview-page-down,alt-k:preview-page-up"
# <tab> already used for multi-select
# $env:FZF_DEFAULT_OPTS="$env:FZF_DEFAULT_OPTS,tab:down,shift-tab:up"

if ((Get-Command "tree" -ErrorAction 'Ignore') -And (Get-Command "tree" -ErrorAction 'Ignore')) {
  $env:FZF_ALT_C_OPTS="${env:FZF_DEFAULT_OPTS} --preview='tree {} | head'"
}
