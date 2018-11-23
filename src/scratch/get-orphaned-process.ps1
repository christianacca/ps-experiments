# WMI class instace to convert WMI time to DateTime 
$wmi = [WMI]'' 
# retrieve and filter running processes 
Get-WmiObject Win32_Process | Where-Object {

    # attempt to retrieve the piped process' parent process 
    $parent = Get-WmiObject Win32_Process -Filter "ProcessID='$($_.ParentProcessID)'" 

    # get the piped process, as well as its parent's, creation time 
    $creationDate, $parentCreationDate = $( 
        # if piped process has a parent and its parent is running 
        if ($_.ParentProcessID -and $parent) { 
            # convert their the WMI creation time to DateTime 
            $wmi.ConvertToDateTime($_.CreationDate), $wmi.ConvertToDateTime($parent.CreationDate) 
        }
        else { 
            # return Null 
            $null, $null 
        }) 

    # filter piped process through if its parent process is not running or 
    # its creation time happened before the parent process was started 
    -not $parent -or $creationDate -lt $parentCreationDate 
} | Select-Object ProcessId, Name | ft -Wrap -AutoSize
# 
# | Get-Process -ID {$_.ProcessID} -IncludeUserName:$false 

# clean up 
Remove-Variable wmi, parent, creationDate, parentCreationDate