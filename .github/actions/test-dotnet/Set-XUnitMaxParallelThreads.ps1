param ($MaxParallelThreads)

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

($configFiles = Get-ChildItem @parameters) | ForEach-Object {
    # Need the parentheses to close the file after reading. Without them, you'll receive an error with Set-Content:
    # "The process cannot access the file '[...]\xunit.runner.json' because it is being used by another process."
    (Get-Content $_) |
        ForEach-Object { $_ -Replace '"maxParallelThreads":\s*([-\d]*)', "`"maxParallelThreads`": $MaxParallelThreads" } |
            Set-Content $_
}

Write-Output "Replaced $($configFiles.Count) occurrences."
