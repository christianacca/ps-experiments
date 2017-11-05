function IsFullPath ([string] $Path) {
    # [System.IO.Path]::

    ![String]::IsNullOrWhiteSpace($Path) -and `
    $Path.IndexOfAny([System.IO.Path]::GetInvalidPathChars()) -eq -1 -and `
    [System.IO.Path]::IsPathRooted($Path) -and `
    ![System.IO.Path]::GetPathRoot($Path).Equals([System.IO.Path]::DirectorySeparatorChar.ToString(), [StringComparison]::Ordinal)
}