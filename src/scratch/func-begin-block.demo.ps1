function Get-EchoValue {
    [CmdletBinding(DefaultParameterSetName='None')]
    param (
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Value,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Type,

        [Parameter(ValueFromPipelineByPropertyName)]
        # [ValidateNotNull()]
        [PSCustomObject] $RefValue = @{},

        [Parameter(Mandatory, ParameterSetName='Delayable')]
        [switch] $Commit
    )
    
    begin {
        Write-Verbose "begin $((Get-Date).Millisecond)"
        Write-Verbose "begin.Value: '$Value'"
        if ([string]::IsNullOrWhiteSpace($Value)) {
            Write-Verbose "setting 'Value' to default"
            $Value = 'DefaultValue'
        }

        Write-Verbose "begin.Type: '$Type'"
        if ([string]::IsNullOrWhiteSpace($Type)) {
            Write-Verbose "setting 'Type' to default"
            $Type = 'http'
        }
    }
    
    process {
        [PsCustomObject] @{
            Response = "process.Value: '$Value'"
            ResponseType = $Type
            At = (Get-Date).Millisecond
            Body = $RefValue
        }
    }
}

$jsonRequest = [PsCustomObject]@{ Type = 'json'; RefValue = $null }
$jsonRequest1 = [PsCustomObject]@{ Type = 'json'; Value = 'axqwd'; RefValue = @{ Initials = 'cc' } }
Write-Host "Starting $((Get-Date).Millisecond)"
@('', 'one', 'two', '') | Get-EchoValue -Type https -Verbose
Write-Host '---'
Write-Output '---'
@('zero', 'one', 'two', $jsonRequest, $jsonRequest1, '', 'three') | Get-EchoValue -Verbose
Write-Host '---'
Write-Output '---'
@($jsonRequest, $jsonRequest1) | Get-EchoValue -Verbose
Write-Host "Ending $((Get-Date).Millisecond)"

<#
Observations:

# piping values to a function
* the begin block is called:
    * Values for parameters supplied as part of the function call will be available in this block
    * The ParameterSet will be determined by the parameters supplied in the function call, falling back to the default set
    * Parameters can be assigned
* the process block is called
    * parameter values extracted from the pipeline input will override any value assigned to the parameter during the begin block
    * if the pipeline input does not bind a value to a parameter, the value assigned to that parameter during the begin block will be available 
* however a default value is assigned to a parameter (eg during begin block), that pipeline input can bind that parameter to a $null

Conclusions

* Consider using the begin block to *dynamically* assign default values to parameters
* Prefer to NOT to use the begin block when default values can be set directly in the parameter declaration
* When an *optional* parameter value MUST not be assigned a null, then either
    * decorate the parameter with a ValidateNotNull attribute when you want to make it mandatory *if supplied*, OR
    * use the process block to assign a default value
#>