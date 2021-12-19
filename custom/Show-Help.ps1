<#

  Prerequisites: PowerShell v5.1 and above (verified; may also work in earlier versions)
  License: MIT
  Author:  Michael Klement <mklement0@gmail.com>
  
  DOWNLOAD and DEFINITION OF THE FUNCTION:

    irm https://gist.github.com/mklement0/880624fd665073bb439dfff5d71da886/raw/Show-Help.ps1 | iex

  The above directly defines the function below in your session and offers guidance for making it available in future
  sessions too.
  
  DOWNLOAD ONLY:
  
    irm https://gist.github.com/mklement0/880624fd665073bb439dfff5d71da886/raw > Show-Help.ps1
    
  The above downloads to the specified file, which you then need to dot-source to make the function available
  in the current session:
  
     . ./Show-Help.ps1
   
  To learn what the function does:
    * see the next comment block
    * or, once downloaded and defined, invoke the function with -? or pass its name to Get-Help.

  To define an ALIAS for the function, (also) add something like the following to your $PROFILE:
  
    Set-Alias shh Show-Help
#>

function Show-Help {

<#
.SYNOPSIS
Wrapper command for the Get-Help cmdlet that shows help topics online rather 
than locally in the console / terminal.

.DESCRIPTION
about_* topics are also supported, via direct construction of the target URL.

-CopyUrl (-cpu) / -CopyLink (-cp) copy the online help topic's URL to the 
clipboard as-is / as a Markdown link instead of opening it in the browser.

For about_CommonParameters and about_Automatic_Variables specifically, you may
pass a specific parameter / variable name as the 2nd positional argument or
via -Anchor. Short parameter aliases such as 'wi' for 'WhatIf' are supported.

Additionally, 'where' and 'foreach' are supported for about_Arrays to look up
the .Where() and .ForEach() array methods.

As an alternative to online lookup you my specify -Local, in which case 
local help content, with the default detail level changed to -Full, is captured
in a temporary file and displayed via your system's default text editor, 

Run Get-Help Get-Help for help on the other parameters.

.EXAMPLE
Show-Help Get-Command

Shows the Get-Command cmdlet's online help topic

.EXAMPLE
Show-Help about_Automatic_Variables HOME

Shows the conceptual help topic about PowerShell's automatic variables online
and jumpts to the description of the $HOME variable, specifically,

.EXAMPLE
Show-Help about_Automatic_Variables HOME -CopyLink

Copies a Markdwown link to the online version of the given conceptual topic
to the clipboard, with the URL pointing to the $HOME variable's description,
specifically. -CopyUrl would copy just the URL.
#>

[CmdletBinding(DefaultParameterSetName = 'AllUsersView', HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=113316')]
param(
  [Parameter(Position = 0)]
  [ValidateNotNullOrEmpty()]
  [ArgumentCompleter( {
      param($cmd, $param, $wordToComplete)
      if ($wordToComplete -like 'about*' -or $wordToComplete -like '_[a-z]*') {
        # As a courtesy, allow '_...' as shorthand for 'about_...'
        $wordToComplete = $wordToComplete -replace '^(?:about)?_', 'about_'
        # Note: This is *slow* and invoked every time what the user typed changes.
        #       Also, it prints a blank line below the current one, curiously.
        (Get-Help -Category HelpFile).Name -like "$wordToComplete*"
      }
      else {
        # Get-Help itself completes those for us, unlike the about_* topics, curiously,
        # even though it does the latter in direct invocation.
        # (Get-Command -Type Alias, Function, Cmdlet).Name -like "$wordToComplete*"
      }
    })]
  [string]
  ${Name},

  # Custom parameter:
  # To support about_CommonParameters and about_Automatic_Variables with a specific
  # parameter / variable name.
  [Parameter(Position = 1)]
  [string]
  $Anchor,

  [string]
  ${Path},

  [ValidateSet('Alias', 'Cmdlet', 'Provider', 'General', 'FAQ', 'Glossary', 'HelpFile', 'ScriptCommand', 'Function', 'Filter', 'ExternalScript', 'All', 'DefaultHelp', 'Workflow', 'DscResource', 'Class', 'Configuration')]
  [string[]]
  ${Category},

  [Parameter(ParameterSetName = 'DetailedView', Mandatory = $true)]
  [switch]
  ${Detailed},

  [Parameter(ParameterSetName = 'AllUsersView')]
  [switch]
  ${Full},

  [Parameter(ParameterSetName = 'Examples', Mandatory = $true)]
  [switch]
  ${Examples},

  [Parameter(ParameterSetName = 'Parameters', Mandatory = $true)]
  [string[]]
  ${Parameter},

  [string[]]
  ${Component},

  [string[]]
  ${Functionality},

  [string[]]
  ${Role},

  [Parameter(ParameterSetName = 'Online', Mandatory = $true)]
  [switch]
  ${Local} # Custom argument - !! inversion of the Get-Help logic
  ,
  [Parameter(ParameterSetName = 'CopyLink', Mandatory = $true)] # Custom argument - copy URL to clipboard as Markdown link.
  [Alias('cp')]
  [switch]
  $CopyLink
  ,
  [Parameter(ParameterSetName = 'CopyUrl', Mandatory = $true)] # Custom argument - copy URL to clipboard
  [Alias('cpu')]
  [switch]
  $CopyUrl
)

Set-StrictMode -Version 1; $ErrorActionPreference = 'Stop'

$copyToClipboard = $CopyUrl -or $CopyLink

# The online help topic should be navigated to by default; -Local overrides in order
# to use the local help content and display it in the default text editor.
$Online = -not $Local

# Remove all wrapper-specific parameters, so that Get-Help @PSBoundParameters (if it is used),
# doesn't break.
foreach ($paramName in 'Local', 'CopyLink', 'CopyUrl') {
  $null = $PSBoundParameters.Remove($paramName)
}
# Conversely, make sure the -Online switch is set appropriately.
if ($Online) { $PSBoundParameters['Online'] = $Online }

$isAboutTopic = $Name -like 'about_*'
$linkLabel = $Name

$topicsSupportedWithAnchor = 'about_CommonParameters', 'about_Automatic_Variables', 'about_Preference_Variables', 'about_Arrays'
if ($Anchor) {
  if (-not (($Online -or $copyToClipboard) -and $Name -in $topicsSupportedWithAnchor)) {
    throw "An -Anchor argument is only supported for online lookups and link/URL copying when combined with the following topics: $($topicsSupportedWithAnchor -join ', ')"
  }
  # Validate the anchor value, based on hard-coded knowledge.
  # !! We do this, because there's no easy way to validate the presence of an anchor on a page, short of downloading the HTML and anlyzing it.
  # !! Because of the hard-coded nature, this may have to be updated over time.
  $validAnchor = switch ($Name) {
    $topicsSupportedWithAnchor[0] {
      # about_CommonParameters
      # Determined with:
      #   (((get-help about_CommonParameters) -split '\r?\n' -match '^\s*-\s+\w+\s+\(.*?\)').Trim('-').Trim() -split '[ ()]' -ne '') -replace '^', "'" -replace '$', "'" -join ', '
      # Note: The casing has been manually corrected to be more eye-friendly.
      $namesAndAliases = 'Debug', 'db', 'ErrorAction', 'ea', 'ErrorVariable', 'ev', 'InformationAction', 'infa', 'InformationVariable', 'iv', 'OutVariable', 'ov', 'OutBuffer', 'ob', 'PipelineVariable', 'pv', 'Verbose', 'vb', 'WarningAction', 'wa', 'WarningVariable', 'wv', 'WhatIf', 'wi', 'Confirm', 'cf'
      # Find the index.
      $ndx = [Array]::FindIndex($namesAndAliases, [Predicate[string]] { $Anchor -eq $args[0] })
      # If the index is an odd number, a short alias name was specified - the immediately preceding name contains the full name, which must be used as the anchor.
      if ($ndx % 2) { --$ndx }
      $Anchor = '-' + $namesAndAliases[$ndx]
      $linkLabel = 'common `-{0}` parameter' -f $namesAndAliases[$ndx] # Use the proper casing
      $ndx -ge 0
    }
    $topicsSupportedWithAnchor[1] {
      # about_Automatic_Variables
      # Determined with:
      #   (((get-help about_automatic_variables) -split '\r?\n' -match '^\s*\$\w+\s*$').Trim().Trim('$') | Sort-Object -Unique) -replace '^', "'" -replace '$', "'" -join ', '
      $names = '?', '_', 'args', 'ConsoleFileName', 'Error', 'Event', 'EventArgs', 'EventSubscriber', 'ExecutionContext', 'false', 'foreach', 'HOME', 'Host', 'input', 'IsCoreCLR', 'IsLinux', 'IsMacOS', 'IsWindows', 'LastExitCode', 'Matches', 'MyInvocation', 'NestedPromptLevel', 'null', 'PID', 'PROFILE', 'PSBoundParameters', 'PSCmdlet', 'PSCommandPath', 'PSCulture', 'PSDebugContext', 'PSHOME', 'PSItem', 'PSScriptRoot', 'PSSenderInfo', 'PSUICulture', 'PSVersionTable', 'PWD', 'Sender', 'ShellId', 'StackTrace', 'switch', 'this', 'true'
      $ndx = [Array]::FindIndex($names, [Predicate[string]] { $Anchor -eq $args[0] })
      $linkLabel = 'automatic `${0}` variable' -f $names[$ndx] # Use the proper casing
      $irregularAnchor = @{ '$'='section'; '?' = 'section-1'; '^' = 'section-2' }[$Anchor]
      if ($irregularAnchor) { $Anchor = $irregularAnchor }
      $ndx -ge 0
    }
    $topicsSupportedWithAnchor[2] {
      # about_Preference_Variables
      # Determined with:
      #   ((get-help about_Preference_Variables) -split '\r?\n' -match '^  \$\w+\s+').ForEach({ (-split $_)[0].TrimStart('$') }) -replace '^', "'" -replace '$', "'" -join ', '
      $names = 'ConfirmPreference', 'DebugPreference', 'ErrorActionPreference', 'ErrorView', 'FormatEnumerationLimit', 'InformationPreference', 'LogCommandHealthEvent', 'LogCommandLifecycleEvent', 'LogEngineHealthEvent', 'LogEngineLifecycleEvent', 'LogProviderLifecycleEvent', 'LogProviderHealthEvent', 'MaximumHistoryCount', 'OFS', 'OutputEncoding', 'ProgressPreference', 'PSDefaultParameterValues', 'PSEmailServer', 'PSModuleAutoLoadingPreference', 'PSSessionApplicationName', 'PSSessionConfigurationName', 'PSSessionOption', 'Transcript', 'VerbosePreference', 'WarningPreference', 'WhatIfPreference'
      $ndx = [Array]::FindIndex($names, [Predicate[string]] { $Anchor -eq $args[0] })
      $linkLabel = 'preference variable `${0}`' -f $names[$ndx] # Use the proper casing
      $ndx -ge 0
    }
    $topicsSupportedWithAnchor[3] {
      # about_Arrays
      #   Just the .Where() and .ForEach() method anchors
      $names = 'Where', 'ForEach'
      $ndx = [Array]::FindIndex($names, [Predicate[string]] { $Anchor -eq $args[0] })
      $linkLabel = '`.{0}()` array method' -f $names[$ndx] # Use the proper casing
      $ndx -ge 0
    }
  }
  if (-not $validAnchor) {
    throw "Invalid -Anchor argument for topic $Name."
  }
  # !! Anchors as URL parts are case-SENSITIVE and must be *all-lowercase*
  $Anchor = $Anchor.ToLowerInvariant()
} 

# Note: For online help it only makes sense to look for topics for names recognized
#       as *commands*.
#       Note: We needn't worry about alias resolution, Get-Help does that automatically.
if ($Online -and $Name -and -not $isAboutTopic -and -not (Get-Command -Ea Ignore $Name)) {
  Throw "No command named '$Name' found."
}

if ($Online -or $copyToClipboard) {

  # Open online help topic in default web browser or copy the topic URL to teh clipboard.
  if ($isAboutTopic) {
    # Sadly, as of 7.0 about_* topics have no online URL information, but it's easy to construct them.
    $url = "https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/$Name"
    if ($Online -and -not $copyToClipboard) {
      # To be consistent with how -Online normally works, append the executing engine's PowerShell version as the version-specific view.
      Start-Process ($url + ('?view=powershell-' + (('{0}.{1}' -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor) -replace '\.0$')) + $(if ($Anchor) { "#$Anchor" }))
      return
    }
  }
  else {
    if ($Online -and -not $copyToClipboard) {
      # Pass through to Get-Help -Online
      Microsoft.PowerShell.Core\Get-Help @PSBoundParameters
      return
    }
    # For -CopyLink and -CopyUrl: Derive the URL from the properties of the target help topic, but strip the version-specific view request,
    # because we want to copy version-agnostic URLs to the clipboard.
    [string] $url = (@((Microsoft.PowerShell.Core\Get-Help -Name $Name).relatedlinks.navigationLink.uri) -ne '')[0] # remove 
    if (-not $url) {
      Throw "No online help-topic URL found for: $Name"
    }
    elseif ($url -like '*go.microsoft.com/fwlink*') {
      # URL is a short version that redirects to the ultimate URL; find that URL and lop off the query-string part.
      try { $url = [System.Net.HttpWebRequest]::Create($url).GetResponse().ResponseUri.AbsoluteUri -replace '\?.+$' } catch { throw }
    }
    # Remove the query-string part, such as '?view=powershell-6&WT.mc_id=ps-gethelp'
    $url = $url -replace '\?.+$'
  }
  if ($Anchor) { 
    $url += "#$Anchor"
  }
  # -CopyLink or -CopyUrl
  # Convert to Markdown links.
  if ($CopyLink) {
    $label = if ($isAboutTopic) {
      $linkLabel
    }
    else {
      $cmd = (Get-Command -Name $Name) # $url -replace '^.*/' -replace '\?.+$' -replace '-', '`'
      if ($cmd.ResolvedCommand) { $cmd = $cmd.ResolvedCommand }
      '`{0}`' -f $cmd.Name
    }
    $textToCopy = '[{0}]({1})' -f $label, $url
  }
  else {
    # $CopyUrl
    $textToCopy = $url
  }

  Write-Verbose "Copying URL / Markdown link to the clipboard: $textToCopy"
  Set-Clipboard $textToCopy
  return
}

# -Local specified:
# Change default detail level to -Full, capture the output in a temporary file,
# and display it in the default text editor.
if (-not $PSBoundParameters.ContainsKey('Full') -or -not $PSBoundParameters.ContainsKey('Detailed') -or -not $PSBoundParameters.ContainsKey('Examples')) {
  $PSBoundParameters.Add('Full', $true)
}

# Use a preexisting Show-Output command to capture the output in a temp. file
# and open it in the default text editor.
# If no such command can be found, define it now.
if (-not ((Get-Command -ErrorAction Ignore Show-Output))) {
  function Show-Output {
    $tmpFile = (Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())) + '.txt'
    $Input > $tmpFile
    Invoke-Item -LiteralPath $tmpFile
    # Quietly try to delete the file after a number of seconds, under the assumption
    # that the text editor that has the file open won't complain.
    Start-Process -NoNewWindow -FilePath (Get-Process -Id $PID).Path -Args '-c', "Start-Sleep 5; Remove-Item -ErrorAction Ignore -LiteralPath `"$tmpFile`""
  }
}

Microsoft.PowerShell.Core\Get-Help @PSBoundParameters | Out-String | Show-Output

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

      # Issue a warning that the function definition didn't take effect and
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
