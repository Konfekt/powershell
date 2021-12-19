Import-WslCommand "ls", "man", "sudo"

Import-WslCommand "mutt"
Import-WslCommand "mbsync"
Import-WslCommand "msmtp-queue"
Import-WslCommand "vdirsyncer"
Import-WslCommand "ikhal"
Import-WslCommand "khal"
Import-WslCommand "khard"
Import-WslCommand "todo"

$WslDefaultParameterValues = @{}
# $WslDefaultParameterValues["<COMMAND>"] = "<ARGS>"
$WslDefaultParameterValues["ls"] = "-AFh --group-directories-first"

# Import-WslCommand "git", "vim"
# Import-WslCommand "awk", "sed", "grep", "head", "tail", "less"
# $WslDefaultParameterValues["grep"] = "-E"
# $WslDefaultParameterValues["less"] = "-i"

# $WslEnvironmentVariables = @{}
# $WslEnvironmentVariables["<NAME>"] = "<VALUE>"
