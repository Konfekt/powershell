Set-Alias o      xdg-open
# Function o(path) {Start-Process $path -NoNewWindow -WindowStyle Minimized}
Function oo      {xdg-open "$(Get-Location)"}

if (Get-Command "xsel" -ErrorAction 'Ignore') {
  Function cb    {xsel --input}
} elseif (Get-Command "xclip" -ErrorAction 'Ignore') {
  Function cb    {xclip -in}
}
