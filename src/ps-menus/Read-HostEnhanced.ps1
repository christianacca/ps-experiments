Function Read-HostEnhanced {
[cmdletbinding(DefaultParameterSetName="_All")]
Param(
    [Parameter(Position = 0,Mandatory,HelpMessage = "Enter prompt text.")]
    [Alias("message")]
    [ValidateNotNullorEmpty()]
    [string]$Prompt,
    [Alias("foregroundcolor","fg")]
    [consolecolor]$PromptColor,
    [ValidateRange(0, 5)]
    [Alias("Tab", "MenuShift")]
    [int]$Shift,
    [string]$Title,
    [consolecolor]$TitleColor,
    [Parameter(ParameterSetName = "SecureString")]
    [switch]$AsSecureString,
    [Parameter(ParameterSetName = "NotNull")]
    [switch]$ValidateNotNull,
    [Parameter(ParameterSetName = "Range")]
    [ValidateNotNullorEmpty()]
    [int[]]$ValidateRange,
    [Parameter(ParameterSetName = "Pattern")]
    [ValidateNotNullorEmpty()]
    [regex]$ValidatePattern,
    [Parameter(ParameterSetName = "Set")]
    [ValidateNotNullorEmpty()]
    [string[]]$ValidateSet
)
 
Write-Verbose "Starting: $($MyInvocation.Mycommand)"
Write-Verbose "Parameter set = $($PSCmdlet.ParameterSetName)"
Write-Verbose "Bound parameters $($PSBoundParameters | Out-String)"

if ($Title) {
    $titleParams = @{
        Object = "$Title`n$("-" * $Title.Length)"
    }
        
    if ($TitleColor) {
        $titleParams.Add("Foregroundcolor", $TitleColor)
    }
    Write-Host @titleParams
}

$Prefix = if ($Shift -gt 0) { [string]"`t" * $Shift } else { '' }
$Text = @"
$Prefix$Prompt : 
"@
$promptHash = @{
    NoNewLine = $True
    Object = $Text
}
 
if ($PromptColor) {
    $promptHash.Add("Foregroundcolor",$PromptColor)
}
 
#display the prompt
Write-Host @promptHash
#get the value
if ($AsSecureString) {
    $r = $host.ui.ReadLineAsSecureString()
}
else {
  #read console input
  $r = $host.ui.ReadLine() 
}

#assume the input is valid unless proved otherwise
$Valid = $True
 
#run validation if necessary
if ($ValidateNotNull) {
    Write-Verbose "Validating for null or empty"
    if($r.length -eq 0 -OR $r -notmatch "\S" -OR $r -eq $Null) {
        $Valid = $False
        Write-Error "Validation test for not null or empty failed."
    }
}
elseif ($ValidatePattern) {
    Write-Verbose "Validating for pattern $($validatepattern.ToString())"
    If ($r -notmatch $ValidatePattern) {
        $Valid = $False
        Write-Error "Validation test for the specified pattern failed."
    }
}
elseif ($ValidateRange) {
    Write-Verbose "Validating for range $($ValidateRange[0])..$($ValidateRange[1]) "
    if ( -NOT ([int]$r -ge $ValidateRange[0] -AND [int]$r -le $ValidateRange[1])) {
        $Valid = $False
        Write-Error "Validation test for the specified range ($($ValidateRange[0])..$($ValidateRange[1])) failed."
    }
    else {
         #convert to an integer
        [int]$r = $r 
    }
}
elseif ($ValidateSet) {
    Write-Verbose "Validating for set $($validateset -join ",")"
    if ($ValidateSet -notcontains $r) {
        $Valid = $False
        Write-Error "Validation test for set $($validateset -join ",") failed."
    }
}
If ($Valid) {
    Write-Verbose "Writing result to the pipeline"
    #any necessary validation passed
    $r
}
Write-Verbose "Ending: $($MyInvocation.Mycommand)"
 
} #end function
