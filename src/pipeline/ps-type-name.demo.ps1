function Get-Name {
    [CmdletBinding(DefaultParameterSetName='None')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Name')]
        [string] $Name,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Widget')]
        [PSTypeName('Widget')]$Widget
    )
    
    process {
        $PSCmdlet.ParameterSetName
        switch ($PSCmdlet.ParameterSetName) {
            'Widget' { $Widget.Name }
            'Name' { $Name }
            Default { throw "'$($PSCmdlet.ParameterSetName)' not implemented"}
        }
    }
}

$goodWidget = [PsCustomObject]@{
    PSTypeName = 'Widget'
    Name = 'Menu'
}

$badWidget = [PsCustomObject]@{
    Name = 'Menu'
}

$goodWidget | Get-Name
$badWidget | Get-Name