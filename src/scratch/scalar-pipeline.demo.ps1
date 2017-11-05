function Get-One {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string] $Value
    )
    
    process {
        if ($Value -eq 'b') {
            @()
            return
        }
        if ($Value -eq 'd') {
            @(2)
            return
        }
        Write-Output 1
    }
}

$scalarValue = @('a') | Get-One
$scalarValue.GetType() # returns Int32

$scalarValue2 = Get-One 'a'
$scalarValue2.GetType() # returns Int32

$scalarValue3 = $null | Get-One
$scalarValue3.GetType() # returns Int32

$scalarValue4 = @('b') | Get-One
$scalarValue4 -eq $null # returns true

$scalarValue5 = @('d') | Get-One
$scalarValue5.GetType() # returns Int32

$scalarValue6 = @('a', 'b') | Get-One
$scalarValue6.GetType() # returns Int32

$scalarValue7 = @('a', 'b', 'c') | Get-One | Select-Object -First 1
$scalarValue7.GetType() # returns Int32

$multiValue = @('a', 'c') | Get-One
$multiValue.GetType() # returns Array

@('a') | Get-One -OutVariable multiValue2
$multiValue2.GetType() # returns Array


# throws:
# $multiValue3 = Get-One @('a', 'b')
# $multiValue3.GetType()

<#
Conclusions...

* advanced function receive one input:
    * the result will be a scalar value
    * the result will be $null if the function does not write output to the pipeline
* advanced function receives two input's:
    * the result will be an array, unless...
    * ... the second value does not write output to the pipeline, then the result will be a scalar value as above
* advanced function's automatically flatten array's written to the output
    * where the function receives one input and outputs an empty array to the pipeline the result
      will be a $null scalar value
    * where the function receives one input and outputs an single element array to the pipeline the result
      will be a scalar value

#>