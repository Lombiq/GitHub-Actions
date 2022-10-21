param ($MaxParallelThreads)

Write-Output "Replacing maxParallelThreads in xunit.runner.json files to $MaxParallelThreads."

($configFiles = Get-ChildItem -Filter xunit.runner.json -Recurse -FollowSymlink -WarningAction Ignore) | ForEach-Object {
     (Get-Content $_) |
        ForEach-Object  {$_ -Replace '"maxParallelThreads":\s*([-\d]*)', "`"maxParallelThreads`": $MaxParallelThreads"} |
        Set-Content $_
}

Write-Output "Replaced $($configFiles.Count) occurrences."
