<#

  Prerequisites: PowerShell v5.1 and above (verified; may also work in earlier versions)
  License: MIT
  Author:  Michael Klement <mklement0@gmail.com>

  DOWNLOAD and DEFINITION OF THE FUNCTION:

    irm https://gist.github.com/mklement0/9e1f13978620b09ab2d15da5535d1b27/raw/Time-Command.ps1 | iex

  The above directly defines the function below in your session and offers guidance for making it available in future
  sessions too.

  DOWNLOAD ONLY:

    irm https://gist.github.com/mklement0/9e1f13978620b09ab2d15da5535d1b27/raw > Time-Command.ps1

  Thea above downloads to the specified file, which you then need to dot-source to make the function available
  in the current session:

     . ./Time-Command.ps1
   
  To learn what the function does:
    * see the next comment block
    * or, once downloaded and defined, invoke the function with -? or pass its name to Get-Help.

  To define an ALIAS for the function, (also) add something like the following to your $PROFILE:
  
    Set-Alias tcm Time-Command

 #>

function Time-Command {
  <#
  .SYNOPSIS
    Times the execution of one or more commands.

  .DESCRIPTION
    Times the execution of one or more commands, averaging the timings of
    10 runs by default; use -Count to customize.

    The commands' output is suppressed by default.
    -OutputToHost prints it, but only straight to the host (console).

    To see the total execution time and other diagnostic info, pass -Verbose.

    The results are reported from fastest to slowest.

  .PARAMETER ScriptBlock
    The commands to time, passed as an array of script blocks, optionally
    via the pipeline.

  .PARAMETER Count
    How many times to run each command; defaults to 10.
    The average timing will be reported.

  .PARAMETER InputObject
    Optional input objects to expose to the script blocks as variable $_.

    $_ refers to the *entire collection* of input objects, whether
    you supply the objects via the pipeline or as an argument.

    Note that this requires that even with pipeline input *all input must
    be collected in memory first*.

  .PARAMETER OutputToHost
    Prints the commands' (success) output, which is suppressed by default,
    directly to the host (console).
    Note:
      * You cannot capture such output.
      * Printing the output clearly affects the duration of the execution.
    The primary purpose of this switch is to verify that the commands work
    as intended.

  .OUTPUTS
  [pscustombject] A custom object with the following properties:
  Factor ... relative performance ratio, with 1.00 representing the fastest
    command. A factor of 2.00, for instance, indicates that the given command
    took twice as long to run as the fastest one.
  Secs (<n>-run avg.) ... a friendly string representation of the execution
    times in seconds; the number of averaged runs in reflected in the property
    name. For programmatic processing, use .TimeSpan instead.
  Command ... the command at hand, i.e., the code inside a script block passed
    to -ScriptBlock.
  TimeSpan ... the execution time of the command at hand, as a [timespan]
    instance.

  .EXAMPLE
  Time-Command { Get-ChildItem -recurse /foo }, { Get-ChildItem -recurse /bar } 50

  Times 50 runs of two Get-ChildItem commands and reports the average execution
  time.

  .EXAMPLE
  'hi', 'there' | Time-Command { $_.Count } -OutputToHost

  Shows how to pass input objects to the script block and how to reference
  them there. Output is 2, because $_ refers to the entire collection of input
  objects.

  .NOTES
  This function is meant to be an enhanced version of the built-in
  Measure-Command cmdlet that improves on the latter in the following ways:
   * Supports multiple commands whose timings can be compared.
   * Supports averaging the timings of multiple runs per command.
   * Supports passing input objects via the pipeline that the commands see
     as the entire collection in variable $_
   * Supports printing command output to the console for diagnostic purposes.
   * Runs the script blocks in a *child* scope (unlike Measure-Object) which
     avoids pollution of the caller's scope and the execution slowdown that
     happens with dot-sourcing
     (see https://github.com/PowerShell/PowerShell/issues/8911).
  * Also published as a Gist: https://gist.github.com/mklement0/9e1f13978620b09ab2d15da5535d1b27
#>

  [CmdletBinding(PositionalBinding = $False)]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Mandatory, Position = 0)]
    [scriptblock[]] $ScriptBlock
    ,
    [Parameter(Position = 1)]
    [int] $Count = 10
    ,
    [Parameter(ValueFromPipeline, Position = 2)]
    [object[]] $InputObject
    ,
    [switch] $OutputToHost
  )

    begin {
      # IMPORTANT:
      # Declare all variables used in this cmdlet with $private:...
      # so as to prevent them from shadowing the *caller's* variables that
      # the script blocks may rely upon.
      # !! See below re manual "unshadowing" of the *parameter* variables.
      $private:dtStart = [datetime]::UtcNow
      $private:havePipelineInput = $MyInvocation.ExpectingInput
      [System.Collections.ArrayList] $private:inputObjects = @()
      # To prevent parameter presets from affecting test results,
      # create a local, empty $PSDefaultParameterValues instance.
      $PSDefaultParameterValues = @{ }
    }

    process {
      # Collect all pipeline input.
      if ($havePipelineInput) { $inputObjects.AddRange($InputObject) }
    }

    end {

      if (-not $havePipelineInput) { $inputObjects = $InputObject }

      # !! The parameter variables too may accidentally shadow *caller* variables
      # !! that the script blocks passed may rely upon.
      # !! We don't bother trying to *manually* "unshadow" ALL parameter variables,
      # !! but we do it for -Count / $Count, because it is such a common variable name.
      # !! Note that this unshadowing will NOT work if the caller is in a different
      # !! scope domain.
      $__tcm_runCount = $Count # !! Cannot use $private, because it is used in child scopes of calculated properties.
      $Count = Get-Variable -Scope 1 Count -ValueOnly -ErrorAction Ignore

      # Time the commands and sort them by execution time (fastest first):
      [ref] $__tcm_fastestTicks = 0 # !! Cannot use $private, because it is used in child scopes of calculated properties.
      $ScriptBlock | ForEach-Object {
        $__tcm_block = $private:blockToRun = $_  # !! Cannot use $private, because it is used in child scopes of calculated properties.
        if ($OutputToHost) {
          # Note: We use ... | Out-Host, which prints to the console, but faster
          #       and more faithfully than ... | Out-String -Stream | Write-Verbose would.
          #       Enclosing the original block content in `. { ... }` is necessary to ensure that
          #       Out-Default applies to *all* statements in the block, if there are multiple.
          $blockToRun = [scriptblock]::Create('. {{ {0} }} | Out-Host' -f $__tcm_block.ToString())
        }
        Write-Verbose "Starting $__tcm_runCount run(s) of: $__tcm_block..."
        # Force garbage collection now, to minimize the risk of collection kicking in during
        # execution due to memory pressure from previous runs.
        [GC]::Collect(); [GC]::WaitForPendingFinalizers()
        1..$__tcm_runCount | ForEach-Object {
          # Note how we pass all input objects as an *argument* to -InputObject
          # so that the script blocks can refer to *all* input objects as $_
          # !! Run the script block via a wrapper that executes it in a *child scope*
          # !! to as to eliminate the effects of variable lookups that occur in
          # !! (implicitly) dot-sourced code.
          # !! (Measure-Command runs its script-block argument dot-sourced).
          # !! See https://github.com/PowerShell/PowerShell/issues/8911
          Measure-Command { & $blockToRun } -InputObject $inputObjects
        } | Measure-Object -Property Ticks -Average |
          Select-Object @{ n = 'Command'; e = { $__tcm_block.ToString().Trim() } },
          @{ n = 'Ticks'; e = { $_.Average } }
  } | Sort-Object Ticks |
    # Note: Choose the property order so that the most important information comes first:
    #       Factor, (friendly seconds, followed by the potentially truncated Command (which is not a problem - it just needs to be recognizable).
    #       The TimeSpan column will often not be visible, but its primary importance is for *programmatic* processing only.
    #       A proper solution would require defining formats via a *.format.ps1xml file.
    Select-Object @{ n = 'Factor'; e = { if ($__tcm_fastestTicks.Value -eq 0) { $__tcm_fastestTicks.Value = $_.Ticks }; '{0:N2}' -f ($_.Ticks / $__tcm_fastestTicks.Value) } },
    @{ n = "Secs ($__tcm_runCount-run avg.)"; e = { '{0:N3}' -f ($_.Ticks / 1e7) } },
    Command,
    @{ n = 'TimeSpan'; e = { [timespan] [long] $_.Ticks } }

  Write-Verbose "Overall time elapsed: $([datetime]::UtcNow - $dtStart)"

  }

}



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
