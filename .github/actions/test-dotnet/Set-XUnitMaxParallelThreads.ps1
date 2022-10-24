param (
    [Parameter(Mandatory=$true)]    
    $MaxParallelThreads
)

Write-Output "Setting maxParallelThreads in xunit.runner.json files to $MaxParallelThreads."

$parameters = @{
        # -Filter is the fastest way to find files because its value is passed directly to the file system API.
        Filter = "xunit.runner.json"
        Recurse = $true
        # -FollowSymLink is needed because without it errors will be thrown of type: 
        # "Get-ChildItem: The system cannot find the path specified."
        FollowSymlink = $true
        # Ignore warnings that will be printed due to multiple symlinks pointing to the same physical file.
        WarningAction = "Ignore"
}

$configFiles = Get-ChildItem @parameters

$configFiles | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_) -Replace '"maxParallelThreads":\s*([-\d]*)', "`"maxParallelThreads`": $MaxParallelThreads"
    $content > $_
}

Write-Output "Replaced $($configFiles.Count) occurrences."
