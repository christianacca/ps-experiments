# Begin: Alternative ways of performing a `Select`(aka `map`)

Get-IISSite -pv site |
    select -Exp Applications -pv app |
    Get-IISAppPool -Name {$_.ApplicationPoolName} -pv pool |
    select  `
@{n = 'Site_Name'; e = {$site.Name}},
@{n = 'App_Name'; e = {$app.Path}}, 
@{n = 'AppPool_Name'; e = {$app.ApplicationPoolName}},
@{n = 'AppPool_IdentityType'; e = {$pool.ProcessModel.IdentityType}},
@{n = 'AppPool_User_Name'; e = {$pool.ProcessModel.UserName}} |
    ft * -AutoSize

dir -Recurse -Directory |
    foreach -Begin { 
    $h = @{}; $result = @();
} -Process {
    $stat = dir $_.FullName -Recurse -File| measure Length -Sum;
    $h.Path = $_.FullName; $h.Files = $stat.Count; $h.TotalSize = $stat.Sum;
    $result += [PSCustomObject]$h;
} -End {
    $result
}

$cmd = {
    dir -Recurse -Directory |
        foreach {
        $stat = dir $_.FullName -Recurse -File| measure Length -Sum;
        [PSCustomObject]@{Path = $_.FullName; Files = $stat.Count; TotalSize = $stat.Sum}
    }
}

$cmd2 = {
    dir -Recurse -Directory |
        select FullName, @{n = 'Stats'; e = { dir $_.FullName -Recurse -File| measure Length -Sum }} |
        select FullName,
    @{n = 'Files'; e = {$_.Stats.Count}},
    @{n = 'TotalSize'; e = {$_.Stats.Sum}}
}

$select = {
    Get-EventLog Application -EntryType Error, Information -Newest 1000 |
        group Source |
        select Name,
    @{
        n = 'Header'; 
        e = { "$($_.count) entries" }
    },
    @{
        n = 'Lines'; 
        e = { $_.group | foreach {
                $_ | select TimeGenerated | Out-String;
                $_ | select -ExpandProperty Message | Out-String;
            } }
    }
}
# End: Alternative ways of performing a `Select`(aka `map`)

New-Item C:\Scrap\Events -ItemType Directory -Force
& $select | foreach {
    $filePath = Join-Path C:\Scrap\Events "$($_.Name).txt";
    $_.Header | Out-File $filePath -Force;
    $_.Lines | foreach {
        $_ | Out-File $filePath -Append;
    }
    Get-Item $filePath
}


# Procedural / non-FP way of writing event log entries to file
$cmd3 = {
    Get-EventLog Application -EntryType Error, Information -Newest 1000 |
        group Source |
        foreach {
        $filePath = Join-Path C:\Scrap\Events "$($_.Name).txt";
        "$($_.count) entries" | Out-File $filePath -Force;
        $_.group | foreach {
            $_ | select TimeGenerated | Out-File $filePath -Append;
            $_ | select -ExpandProperty Message | Out-File $filePath -Append;
        }
        Get-Item $filePath
    }
}

& $cmd3