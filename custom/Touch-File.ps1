<#

  Prerequisites: PowerShell v5.1 and above (verified; may also work in earlier versions)
  License: MIT
  Author:  Michael Klement <mklement0@gmail.com>

  DOWNLOAD and INSTANT DEFINITION OF THE FUNCTION:

    irm https://gist.github.com/mklement0/82ed8e73bb1d17c5ff7b57d958db2872/raw/Touch-File.ps1 | iex

  The above directly defines the function below in your session and offers guidance for making it available in future
  sessions too.

  DOWNLOAD ONLY:

    irm https://gist.github.com/mklement0/82ed8e73bb1d17c5ff7b57d958db2872/raw > Touch-File.ps1

  Thea above downloads to the specified file, which you then need to dot-source to make the function available
  in the current session:

     . ./Touch-File.ps1
   
  To learn what the function does:
    * see the next comment block
    * or, once downloaded and defined, invoke the function with -? or pass its name to Get-Help.

  To define an ALIAS for the function, (also) add something like the following to your $PROFILE:
  
    Set-Alias tf Touch-File

#>

function Touch-File {

<#
.SYNOPSIS
"Touches" files.

.DESCRIPTION
Similar to the Unix touch utility, this command updates the last-modified and
last-accessed timestamps of files or creates files on
demand.

The current point in time is used by default, but you can pass a
specific timestamp with -DateTime or use an existing file or directory's 
last-modified timestamp with -ReferencePath.
Alternatively, the target files' current timestamps can be adjusted with 
a time span passed to -Offset.

Symbolic links are invariably followed, which means that it is a file link's
*target* whose last-modified timestamp get updated.
Note: 
 * This means that a *link*'s timestamp is itself never updated.
 * If a link's target doesn't exist, a non-terminating error occurs.

Use -WhatIf to preview the effects of a given command, and -Verbose to see
details.
Use -PassThru to pass the touched items through, i.e., to output updated
information about them.

Note that in order to pass multiple target files / patterns as arguments
you must *comma*-separate them, because they bind to a single, array-valued
parameter.

.PARAMETER Path
The paths of one or more target files, optionally expressed
as wildcard expressions, and optionally passed via the pipeline.

.PARAMETER LiteralPath
The literal paths of one or more target files, optionally
passed via the pipeline as output from Get-ChildItem or Get-Item.

.PARAMETER DateTime
The timestamp to assign as the last-modified (last-write) and last-access
values.

By default, the current point in time is used.

.PARAMETER ReferencePath
The literal path to an existing file or directory whose last-modified
timestamp should be applied to the target file(s).

.PARAMETER Offset
A time span to apply as an offset to the target files' current last-write
timestamp.

Since the intent is to adust the current timestamps of *existing* files,
non-existent paths are ignored; that is, -NoNew is implied.

Note that positive values adjust the timestamps forward (to a more recent date),
whereas negative values adjust backwards (to an earlier date.)

Examples of strings that can be used to specify time spans:

* '-1' adjust the current timestamp backward by 1 day
* '-2:0' sets it backward by 2 hours 

Alternatively, use something like -(New-TimeSpan -Days 1)

.PARAMETER NoNew
Specifies that only existing files should have their timestamps updated.

By default, literal target paths that do not refer to existing items 
result in files with these paths getting *created* on demand.

A warning is issued for any non-existing input paths.

.PARAMETER PassThru
Specifies that the "touched" items are passed through, i.e. produced as this 
command's output, as System.IO.FileInfo instances.

.PARAMETER Force
When wildcard expressions are passed to -Path, hidden files are matched too.

.EXAMPLE
Touch-File *.txt

Sets the last-modified and last-accessed timestamps for all text files
in the current directory to the current point in time.

.EXAMPLE
Touch-File newfile1, newfile2 -PassThru

Creates files 'newfile1' and 'newfile2' and outputs information about them as 
System.IO.FileInfo instances.
Note the need to use "," to pass multiple paths.

.EXAMPLE
Touch-File *.txt -DateTime (Get-Date).Date

Updates the last-modified and last-accessed timestamps for all text files
in the current directory to midnight (the start of) of today's date.

.EXAMPLE
Get-Item *.txt | Touch-File -Offset '-1:0'

Adjusts the last-modified and last-accessed timestamps of all text files
in the current directory back by 1 hour.

.EXAMPLE
Get-ChildItem -File | Touch-File -ReferencePath .

Sets the last-modified and last-accessed timestamps of all files in the 
current directory to the last-modified timestamp of the current directory.


.NOTES
"Touch" is not an approved verb in PowerShell, but it was chosen nonetheless,
because none of the approved verbs can adequately convey the core functionality
of this command.

In PowerShell *Core*, implementing this command to support multiple target
paths *as individual arguments* (as in Unix touch) would be possible
(via ValueFromRemainingArguments), but such a solution would misbehave in
Windows PowerShell.

#>

# Supports both editions, but requires PSv3+
#requires -version 3  

[CmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess)]
param(
  [Parameter(ParameterSetName = 'Path', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
  [Parameter(ParameterSetName = 'PathAndDateTime', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
  [Parameter(ParameterSetName = 'PathAndRefPath', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
  [string[]] $Path
  ,
  [Parameter(ParameterSetName = 'LiteralPath', Mandatory, ValueFromPipelineByPropertyName)]
  [Parameter(ParameterSetName = 'LiteralPathAndDateTime', Mandatory, ValueFromPipelineByPropertyName)]
  [Parameter(ParameterSetName = 'LiteralPathAndRefPath', Mandatory, ValueFromPipelineByPropertyName)]
  [Alias('PSPath', 'LP')]
  [string[]] $LiteralPath
  ,
  [Parameter(ParameterSetName = 'PathAndRefPath', Mandatory)]
  [Parameter(ParameterSetName = 'LiteralPathAndRefPath', Mandatory)]
  [string] $ReferencePath
  ,
  [Parameter(ParameterSetName = 'PathAndDateTime', Mandatory)]
  [Parameter(ParameterSetName = 'LiteralPathAndDateTime', Mandatory)]
  [datetime] $DateTime
  ,
  [Parameter(ParameterSetName = 'Path')]
  [Parameter(ParameterSetName = 'LiteralPath')]
  [timespan] $Offset
  ,
  [switch] $NoNew
  ,
  [switch] $PassThru
  ,
  [switch] $Force
)

begin { 
  
  Set-StrictMode -Version 1
  $ErrorActionPreference = 'Continue' # We want to pass non-terminating errors / .NET method-call exceptions through.

  $haveRefPath = $PSBoundParameters.ContainsKey('ReferencePath')
  $haveDateTime = $PSBoundParameters.ContainsKey('DateTime')
  $haveOffset = $PSBoundParameters.ContainsKey('Offset')
  if ($haveOffset) { $NoNew = $true } # -NoNew is implied.
  # Initialize defaults (even though they may not be used).
  # Defining them unconditionally prevents strict-mode violations in pseudo-ternary conditionals.
  if (-not ($haveDateTime -or $haveRefPath)) { $DateTime = [datetime]::Now }
  if (-not $haveOffset) { $Offset = 0 }
  # If a reference item was given, obtain its timestamp now and abort if that fails.
  if ($haveRefPath) {
    try {
      $DateTime = (Get-Item -ErrorAction Stop $ReferencePath).LastWriteTime
    }
    catch {
      Throw "Failed to get the reference path's last-modified timestamp: $_"
    }
  }
  $touchedCount = 0

}

process {
  
  $wildcardsSupported = $PSCmdlet.ParameterSetName -notlike 'LiteralPath*'

  # Try to retrieve existing files.
  [array] $files, $dirs = 
  $(
    if ($wildcardsSupported) {
      Get-Item -Path $Path -ErrorAction SilentlyContinue -ErrorVariable errs -Force:$Force
    }
    else {
      Get-Item -LiteralPath $LiteralPath -ErrorAction SilentlyContinue -ErrorVariable errs -Force:$Force
    }
  ).Where( { -not $_.PSIsContainer }, 'Split')

  # Ignore directories among the (globbed) input paths, but issue a warning.
  if ($dirs) {
    Write-Warning "Ignoring *directory* path(s): $dirs"
  }

  # -WhatIf / -Confirm support.
  # Note: The prompt message is also printed with -Verbose
  $targets = ($LiteralPath, ($Path, $files.FullName)[$files.Count -gt 0])[$wildcardsSupported] -replace '^Microsoft\.PowerShell\.Core\\FileSystem::' -replace ('^' + [regex]::Escape($PWD) + '[\\/]?')
  if ($targets.Count -gt 1) { $targets = "`n" + ($targets -join "`n") + "`n" }
  $newDateTimeDescr = if ($haveOffset -and -not ($haveDateTime -or $haveRefPath)) { "the last-modified timestamp offset by $Offset" } else { "$($DateTime + $Offset)" }
  $actionDescr = ("Updating / creating with a last-modified timestamp of $newDateTimeDescr", "Updating the last-modified timestamp to $newDateTimeDescr")[$NoNew.IsPresent]
  if (-not $PSCmdlet.ShouldProcess($targets, $actionDescr)) { return }

  # Weed out *unexpected errors* and pass them through, such as
  # paths whose drive doesn't exist.
  $expectedErrs, $unexpectedErrs = $errs.Where({ $_.Exception -is [System.Management.Automation.ItemNotFoundException] }, 'Split')
  if ($unexpectedErrs) {
    $unexpectedErrs | Write-Error
  }

  # Try to create the files that don't yet exist - unless opt-out -NoNew was specified.
  if ($expectedErrs) {
    if ($NoNew) {
      Write-Warning "Ignoring non-existing path: $($expectedErrs.TargetObject)"
    }
    else {
      $newFilePaths = $expectedErrs.TargetObject # For ItemNotFoundExceptions, .TargetObject contains the offending path.
      Write-Verbose "Creating: $newFilePaths..."
      $files += New-Item -ItemType File -Path $newFilePaths -ErrorAction SilentlyContinue -ErrorVariable errs
      # If any unexpected errors occurred - such as the parent directory of a literal target path not existing - pass them through.
      # By contrast, the file already *existing* is expected (albeit unlikely in practice): a file may have been created by
      # another process or thread between now and the time we ran Get-Item above.
      foreach ($e in $errs) {
        if (-not (Test-Path -PathType Leaf -LiteralPath $e.TargetObject)) { $e | Write-Error }
      }
    }
  }

  # Update the target files' timestamps.
  foreach ($file in $files) {
    # Note: If $file is a symlink, *setting* timestamp properties invariably sets the *target*'s timestamps.
    #       *Getting* a symlink's timestame properties, by contrast, reports the *link*'s.
    #       This means:
    #          * In order to apply an offset to the existing timestamp, we must explicitly get the *target*'s timestamp
    #          * With -PassThru, unfortunately - given that we don't want to quietly switch to the *target* on output -
    #            this means that the passed-through instance will reflect the - unmodified - *link*'s properties.
    $target = 
      if ($haveOffset -and $file.LinkType) {
        # Note: If a link's target doesn't exist, a non-terminating error occurs, which we'll pass through.
        # !! Due to inconsistent behavior of Get-Item as of PowerShell Core 7.2.0-preview.5, if a broken symlink
        # !! is (a) specified literally and (b) alongside at least one other path (irrespective of whether -Path or -LiteralPath is used),
        # !! it generates an *error* - even though passing that path *as the only one* or *by indirect inclusion via a pattern*
        # !! does NOT (it lists the non-existent target in the Name column, but doesn't error).
        # !! Thus, if (a) and (b) apply, the resulting error may have caused the non-existent target to be created above,
        # !! assuming that its parent directory exists.
        Get-Item -Force -LiteralPath $file.Target
      } else { 
        $file 
      }
    if ($target) {
      # Set the last-modified and (always also) the last-access timestamps.
      $target.LastWriteTime = $target.LastAccessTime = if ($haveOffset) { $target.LastWriteTime + $Offset } else { $DateTime }
    }
    if ($PassThru) { $file }
  }
  $touchedCount += $files.Count

}

end {  
  if (-not $WhatIfPreference -and $touchedCount -eq 0) {
    Write-Warning "Nothing to touch."
  }
}

} # function



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
