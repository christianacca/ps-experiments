function Get-Many {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [int] $Value
    )
    
    process {
        if ($Value -eq 2) {
            @()
            return
        }
        Write-Output 'a'
        Write-Output 'b'
    }
}

function Get-Array {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [int] $Value
    )
    
    process {
        if ($Value -eq 2) {
            @()
            return
        }
        $arr = @('a','b')
        $arr
    }
}

$multiValue = @(1) | Get-Many
$multiValue.GetType() # returns Array
$multiValue[0].GetType() # returns string

$multiValue2 = Get-Many 1
$multiValue2.GetType() # returns Array
$multiValue2[0].GetType() # returns string

$multiValue3 = $null | Get-Many
$multiValue3.GetType() # returns Array
$multiValue3[0].GetType() # returns string

$scalarValue = @(2) | Get-Many
$scalarValue -eq $null # returns true

$multiValue4 = @(1, 2) | Get-Many
$multiValue4.GetType() # returns Array

$multiValue5 = @(1) | Get-Array
$multiValue5.GetType() # returns Array
$multiValue5[0].GetType() # returns string

# notice how powershell auto-flattens the arrays returned by Get-Array
@(1, 2, 3) | Get-Array | Select @{n='Value';e={$_}}

<#
Conclusions...

* advanced function auto-flattens arrays written to the output
    * where the function receives one input and outputs an empty array to the pipeline the result
      will be a $null scalar value
    * where the function receives one input and outputs an single element array to the pipeline the result
      will be a scalar value
#>