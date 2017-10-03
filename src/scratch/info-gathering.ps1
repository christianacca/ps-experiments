# Begin: Alternative ways of performing a `Select`(aka `map`)

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
        select FullName, @{Name = 'Stats'; Expression = { dir $_.FullName -Recurse -File| measure Length -Sum }} |
        select FullName,
    @{Name = 'Files'; Expression = {$_.Stats.Count}},
    @{Name = 'TotalSize'; Expression = {$_.Stats.Sum}}
}

$select = {
    Get-EventLog Application -EntryType Error, Information -Newest 1000 |
        group Source |
        select Name,
    @{
        Name       = 'Header'; 
        Expression = { "$($_.count) entries" }
    },
    @{
        Name       = 'Lines'; 
        Expression = { $_.group | foreach {
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