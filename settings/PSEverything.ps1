Set-Alias se Search-Everything

# FuzzySearch, Edit and Open Everything
If (Get-Command "fzf" -ErrorAction 'Ignore') {
  Function fse {Search-Everything | fzf}
} ElseIf (Get-Command "peco" -ErrorAction 'Ignore') {
  Function fse {Search-Everything | peco}
}
Function ee {& "$env:Editor" "$(fse)"}
Function oe {Invoke-Item "$(fse)"}
