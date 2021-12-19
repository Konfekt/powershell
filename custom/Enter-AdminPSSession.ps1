<#

  Prerequisites: PowerShell v3+
  License: MIT
  Author:  Michael Klement <mklement0@gmail.com>

  DOWNLOAD and DEFINITION OF THE FUNCTION:

    irm https://gist.github.com/mklement0/f726dee9f0d3d444bf58cb81fda57884/raw/Enter-AdminPSSession.ps1 | iex

  The above directly defines the function below in your session and offers guidance for making it available in future
  sessions too.

  DOWNLOAD ONLY:

    irm https://gist.github.com/mklement0/f726dee9f0d3d444bf58cb81fda57884/raw > Enter-AdminPSSession.ps1

  The above downloads to the specified file, which you then need to dot-source to make the function available
  in the current session:

     . ./Enter-AdminPSSession.ps1
   
  To learn what the function does:
    * see the next comment block
    * or, once downloaded and defined, invoke the function with -? or pass its name to Get-Help.

  To define an ALIAS for the function, (also) add something like the following to your $PROFILE:
  
    Set-Alias psa Enter-AdminPSSession

#>

function Enter-AdminPSSession {

<#
.SYNOPSIS
Starts a new PowerShell session that runs with administrative privileges on the
local computer, optionally with startup commands and automatic exit.

.DESCRIPTION
* On Windows, the new session invariably runs in a new console window, 
  asynchronously, unless you use -Exit or -ExitOnSuccess.
* On Unix-like platforms, it invariably runs in the current window, 
  synchronously.

Unless the current session is itself elevated, you'll normally be prompted
for confirmation or admin credentials.
Note that, unlike `sudo`, this command always creates a *new* session, even if
the current session is already elevated.

* On Windows, the new session stays open by default, unless you pass commands 
  with -ScriptBlock and also use either the -Exit or -ExitOnSuccess switch.

* On Unix, the new session is exited automatically when commands are passed,
  unless you pass -NoExit.

"[admin] " is prepended to the prompt string in the new session and the calling
shell's current location (working directory) is preserved, except if
the new session runs in the ISE.

If you pass commands and you must programmatically check for successful
execution, use -Exit and test $LASTEXITCODE for 0 (success).

Only on Unix, where the session runs in the calling terminal window, can you
capture or redirect output.
Unfortunately, as of PowerShell Core 7.2, the PowerShell CLI reports all of its
output streams via *stdout*, which the calling PowerShell session therefore 
sees in its success output stream. However, you can apply a redirection to the
error stream (2), which then does redirect the admin session's error output only.

.PARAMETER ScriptBlock
A script block containing the command(s) to execute in the admin session on
startup.

NOTE:

* To reference variables from the *calling* session, pass them
  *as arguments* to the script block passed to -ScriptBlock, and reference them
  via $args or declared parameters there - `$using:<varName>` will NOT work.

* If you use this parameter when calling from the ISE, the new session
  will open in a regular PowerShell window, because the ISE doesn't support
  passing start-up commands via its CLI.

.PARAMETER ArgumentList
Arguments, if any, to pass to the script block, *as an array*, as you'd have
to with Start-Process.

You can pass them free-form, without prefixing them with -Arguments,
but any accidentally misspelled forms of other parameter names
will then be bound to this parameter.

If you do specify -Arguments, separate the values with commas; i.e.,
you must then pass them as an array.

In any event, '-'-prefixed arguments to pass through must be quoted, so that
they're not mistaken for parameters to the internally used Start-Process call.

Note that only arguments that round-trip properly when converted to and from
a *string* are supported, because a call to an external program -
even if that program is again PowerShell - only supports passing *string*
arguments.

.PARAMETER NoProfile
Suppresses loading of the profiles in the new session.

.PARAMETER Exit
Unconditionally closes the session after executing the command(s) passed
via -ScriptBlock. Note that the caller is blocked until the session closes.

Implied on Unix if a command is passed to -ScriptBlock.

An attempt is made to reflect overall success of the command(s) passed to
-ScriptBlock in $LASTEXITCODE: $LASTEXITCODE is set to 0 (success) only if
all of the following conditions are met:
* $? is $true after executing the command(s).
* $LASTEXITCODE has either never been set or is 0.
Note that, for technical reasons, $? cannot be made to reflect failure.

Caveat on Windows: Since the new session invariably runs in a new window,
you won't see command output after the session exits, because the window
closes automatically, which can cause you to miss errors.
Use -ExitOnSuccess instead to keep the session open if the command(s) didn't
succeed overall.

.PARAMETER ExitOnSuccess
Closes the session automatically only if executing the
specified command(s) was successful, where success is defined the same way
as for the -Exit switch and that the caller is blocked until the session closes.

If you want to ensure that *any* error that occurs during execution aborts
execution of the commands and keeps the session open, begin your commands with
  $ErrorActionPreference = 'Stop'

Conversely, if you want to force your commands to be considered successful,
end your commands with
  $LASTEXITCODE = 0

Note that neither $? nor $LASTEXITCODE will have a meaningful value on
returning from the call; use -Exit instead, if that is necessary.

.PARAMETER NoExit
Unconditionally keeps the elevated ession open after executing the comamands 
passed via -ScriptBlock.

Explicit use of this switch is only needed on Unix, given that on Windows
the session stays open by default, even when passing commands, given that the
elevated session invariably runs in a new window.
(Keeping the session in the new window open ensures that the command output
can be inspected before the window is closed.)

.NOTES
Consider defining an alias, such as:

    # Easy to remember, but doesn't conform to PowerShell's naming rules.
    Set-Alias psa Enter-AdminPSSession

    # Conformant, but somewhat unwieldy.
    # ('et' for 'Enter', 'a' for admin, and 'sn'` for session).
    Set-Alias etasn Enter-AdminPSSession

.EXAMPLE
Enter-AdminPSSession

Enters an elevated PowerShell session, in the current location.
On Windows, the session will run in a new window, on Unix in the current one.

.EXAMPLE
Enter-AdminPSSession -NoProfile

Enters an admin PowerShell session without loading profiles.

.EXAMPLE
Enter-AdminPSSession { winrm quickconfig } -ExitOnSuccess

Enters an admin PowerShell session and executes command `winrm quickconfig`,
then exits the session if the command succeeded (if winrm's exit code was 0).

.EXAMPLE
Enter-AdminPSSession { ls /usr/sbin/authserver }

On Unix: Enters an admin PowerShell session and executes an ls command,
then uncoditionally exits the session. The ls call's exit code will be
reflected in $LASTEXITCODE.
To keep the session open, pass -NoExit

.EXAMPLE
Enter-AdminPSSession { "The elevated session's PID is: $PID; the parent's is: $args" } $PID

Enters an admin PowerShell session and executes the specified script block,
passing it the calling session's process ID.
#>

[CmdletBinding(DefaultParameterSetName='Interactive', PositionalBinding=$false)]
param(
  [Parameter(ParameterSetName='Command', Position=0, Mandatory)]
  [scriptblock] $ScriptBlock
  ,
  [Parameter(ParameterSetName='Command', Position=1)]
  [Alias('Args')]
  [object[]] $ArgumentList
  ,
  [Parameter(ParameterSetName='Interactive')]
  [Parameter(ParameterSetName='Command')]
  [switch] $NoProfile
  ,
  [Parameter(ParameterSetName='Command')]
  [switch] $ExitOnSuccess
  ,
  [Parameter(ParameterSetName='Command')]
  [switch] $Exit
  ,
  [Parameter(ParameterSetName='Command')]
  [switch] $NoExit
)

# Note: To avoid proliferation of parameter sets, we use a single 'Command' set
#       for all of the following switches and enforce exclusion manually:
#       -Exit -ExitOnSuccess -NoExit
if (1 -lt ([int] $NoExit.IsPresent + [int] $Exit.IsPresent + [int] $ExitOnSuccess.IsPresent)) {
  Throw "The -NoExit, -Exit, and -ExitOnSuccess switches are mutually exclusive."
} 

# Helper function that stringifies an argument.
function stringify($arg) {
  if ($arg -is [scriptblock]) {
    '{' + $arg.ToString() + '}'
  } elseif($arg -is [System.Collections.IList]) { # arrays and array-like types, excluding hashtables
    $(foreach($argEl in $arg) { stringify $argEl }) -join ', '
  } else {
    "'" + ($arg -replace "'", "''") + "'"
  }
}

# Decide whether the elevated session should be kept open *by default* if a command is given:
#  * Windows: Yes, since the fact that a new window is being created would otherwise mean that command output will disappear when the window closes.
#  * Unix:    No, since the command runs visibly and synchronously in the same window as the caller, via `sudo`
if (-not ($PSBoundParameters.ContainsKey('Exit') -or $PSBoundParameters.ContainsKey('ExitOnSuccess') -or $PSBoundParameters.ContainsKey('NoExit'))) {
  if ($ScriptBlock) {
    $NoExit = if ($env:OS -eq 'Windows_NT') { $true }
              else                          { $false }
  } else {
    $NoExit = $true # interactive session: do not exit by definition (note: -NoExit is still needed, since we always pass helper code via -c)
  }
}
elseif ($ExitOnSuccess) {
  $NoExit = $true # Must keep the session open by default; the helper code then decides whether to exit.
}

# Use the same PowerShell executable that started this session.
$psExePath = (Get-Process -Id $PID).Path
# Exception: The ISE doesn't support passing commands on startup, so if -ScriptBlock
# was specified, we must use powershell.exe instead.
$isIse = $psExePath -like '*\powershell_ise.exe'
$useIse = $isIse -and -not $ScriptBlock # ISE can only be used if no command was given.
if ($isIse -and -not $useIse) {
  # Must use powershell.exe instead, if a command was given.
  Write-Warning "Admin session will open in a regular PowerShell console, because the ISE doesn't support passing commands on startup."
  $psExePath = $psExePath -replace '_ise(?=\.exe$)'
}

# Compose the custom command to pass to -EncodedCommand as a single string.

if ($useIse) {
  $cmd = '' # no commands supported; note that this means that the current location cannot be set either, nor can the prompt string be prefixed.
} else {

  # Prepend '[admin]' to the prompt string to make it clear that the session is an admin one
  # (Not needed if unconditional exiting is requested.)
  $cmd = if ($Exit) { '' } else { '$function:prompt = ''Write-Host -NoNewline "[admin] "; '' + $function:prompt; ' }

  # Windows PowerShell: Start-Process doesn't respect -WorkingDir with -Verb RunAs, so we must prepend an explicit Set-Location commmand.
  $cmd += if ($PSVersionTable.PSEdition -ne 'Core') { "Set-Location $(stringify $PWD);" }

  # If a script block was passed, add it, along with pass-thru arguments, if any.
  # Also add code to handle automatic exit and setting the exit code; note that the latter must
  # be inside the script block in order for $? to have a meaningful value.
  $cmd += if ($ScriptBlock) {
    '$Error.Clear(); $LASTEXITCODE = 0; . {{ {0}{1} }} {2}' -f
      $ScriptBlock.ToString(),
      $(
        if ($ExitOnSuccess) { '; if ($? -and [int] $LASTEXITCODE -eq 0) { exit 0 } else { Write-Warning "Keeping session open due to errors." }' }
        elseif ($Exit)      { '; if (-not $?) { exit 1 } elseif ($LASTEXITCODE) { exit $LASTEXITCODE } else { exit 0 }' } # make an attempt to pass the exit code through.
      ),
      (stringify $ArgumentList)
  }

}

# Construct the PowerShell CLI arguments.
$psCliArgs = @()
if ($NoExit)    { $psCliArgs += '-NoExit' }
if ($NoProfile) { $psCliArgs += '-NoProfile' }
if ($cmd)       { $psCliArgs += '-EncodedCommand', [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd)) }

Write-Verbose ("Command line to execute (unencoded):`n$psExePath $("$psCliArgs" -replace '-EncodedCommand .*')" + $(if ($cmd) { "-c '$($cmd -replace "'", "''")'" }))

# Enter the admin session:
if ($env:OS -eq 'Windows_NT') { # Windows, both editions: Start-Process -Verb RunAs
  # If -Exit or -ExitOnSuccess were given, wait for the admin session to close.
  $ps = if ($psCliArgs) {
    Start-Process -Verb RunAs -PassThru -Wait:($Exit -or $ExitOnSuccess) -FilePath $psExePath -ArgumentList $psCliArgs
  } else {
    Start-Process -Verb RunAs -PassThru -Wait:($Exit -or $ExitOnSuccess) -FilePath $psExePath
  }
  # Set the global $LASTEXITCODE only if -Exit was given; the exit code of an interactive session cannot be considered intentional
  # and we have no way of knowing with -ExitOnSuccess whether the command passed to the session was ultimately successful or not.
  if ($Exit) { $global:LASTEXITCODE = $ps.ExitCode }
} else { # Unix (PS Core): sudo
  # Note: sudo:
  # * executes the command synchronously, in the same window.
  # * passes the invoked program's exit code through.
  # * allows capturing the command's output by the caller.
  sudo $psExePath $psCliArgs 
}

} # end of function 

# --------------------------------
# GENERIC INSTALLATION HELPER CODE
# --------------------------------
#    Provides guidance for making the function persistently available when
#    this script is either directly invoked from the originating Gist or
#    dot-sourced after download.
#    IMPORTANT: 
#       * DO NOT USE `exit` in the code below, because it would exit
#         the calling shell when Invoke-Expression is used to directly
#         execute this script's content from GitHub.
#       * Because the typical invocation is DOT-SOURCED (via Invoke-Expression), 
#         do not define variables or alter the session state via Set-StrictMode, ...
#         *except in child scopes*, via & { ... }
if ($MyInvocation.Line -eq '') {
  # Most likely, this code is being executed via Invoke-Expression directly 
  # from gist.github.com

  # To simulate for testing with a local script, use the following:
  # Note: Be sure to use a path and to use "/" as the separator.
  #  iex (Get-Content -Raw ./script.ps1)

  # Derive the function name from the invocation command, via the enclosing
  # script name presumed to be contained in the URL.
  # NOTE: Unfortunately, when invoked via Invoke-Expression, $MyInvocation.MyCommand.ScriptBlock
  #       with the actual script content is NOT available, so we cannot extract
  #       the function name this way.
  & {
    
    param($invocationCmdLine)
    
    # Try to extract the function name from the URL.
    $funcName = $invocationCmdLine -replace '^.+/(.+?)(?:\.ps1).*$', '$1'
    if ($funcName -eq $invocationCmdLine) {
      # Function name could not be extracted, just provide a generic message.
      # Note: Hypothetically, we could try to extract the Gist ID from the URL
      #       and use the REST API to determine the first filename.
      Write-Verbose -Verbose "Function is now defined in this session."
    } 
    else {

      # Indicate that the function is now defined and also show how to
      # add it to the $PROFILE or convert it to a script file.
      Write-Verbose -Verbose @"
Function `"$funcName`" is now defined in this session.

* If you want to add this function to your `$PROFILE, run the following:

   "``nfunction $funcName {``n`${function:$funcName}``n}" | Add-Content `$PROFILE

* If you want to convert this function into a script file that you can invoke
  directly, run:

   "`${function:$funcName}" | Set-Content $funcName.ps1 -Encoding $('utf8' + ('', 'bom')[[bool] (Get-Variable -ErrorAction Ignore IsCoreCLR -ValueOnly)])

"@
    }

  } $MyInvocation.MyCommand.Definition # Pass the original invocation command line to the script block.

}
else {
  # Invocation presumably as a local file after manual download, 
  # either dot-sourced (as it should be) or mistakenly directly.  

  & {
    param($originalInvocation)

    # Parse this file to reliably extract the name of the embedded function, 
    # irrespective of the name of the script file.
    $ast = $originalInvocation.MyCommand.ScriptBlock.Ast
    $funcName = $ast.Find( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false).Name

    if ($originalInvocation.InvocationName -eq '.') {
      # Being dot-sourced as a file.
      
      # Provide a hint that the function is now loaded and provide
      # guidance for how to add it to the $PROFILE.
      Write-Verbose -Verbose @"
Function `"$funcName`" is now defined in this session.

If you want to add this function to your `$PROFILE, run the following:

    "``nfunction $funcName {``n`${function:$funcName}``n}" | Add-Content `$PROFILE

"@

    }
    else {
      # Mistakenly directly invoked.

      # Issue a warning that the function definition didn't effect and
      # provide guidance for reinvocation and adding to the $PROFILE.
      Write-Warning @"
This script contains a definition for function "$funcName", but this definition
only takes effect if you dot-source this script.

To define this function for the current session, run:
  
  . "$($originalInvocation.MyCommand.Path)"
  
"@
    } 

  }  $MyInvocation # Pass the original invocation info to the helper script block.

}