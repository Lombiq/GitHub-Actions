param ($MaxParallelThreads)

Write-Output "Replacing maxParallelThreads in xunit.runner.json files to $MaxParallelThreads."

($configFiles = Get-ChildItem -Filter xunit.runner.json -Recurse -FollowSymlink -WarningAction Ignore) | ForEach-Object {
    # Need the parentheses to close the file after reading. Without them, you'll receive an error with Set-Content:
    # "The process cannot access the file '[...]\xunit.runner.json' because it is being used by another process."
    (Get-Content $_) |
        ForEach-Object { $_ -Replace '"maxParallelThreads":\s*([-\d]*)', "`"maxParallelThreads`": $MaxParallelThreads" } |
            Set-Content $_
}

Write-Output "Replaced $($configFiles.Count) occurrences."
