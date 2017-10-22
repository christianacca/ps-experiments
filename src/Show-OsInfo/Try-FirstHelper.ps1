function Try-FirstHelper {
    param([scriptblock[]] $Actions)
    
    $ErrorActionPreference = 'Stop'
    foreach ($a in $Actions) {
        try {
            return & $a
        }
        catch {
            continue;
        }
    }
}