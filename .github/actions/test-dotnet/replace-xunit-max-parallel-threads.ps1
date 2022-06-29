param ($MaxParallelThreads)

Write-Output "Replacing maxParallelThreads in xunit.runner.json files to $MaxParallelThreads."

($configFiles = Get-ChildItem "*/**/xunit.runner.json" -Recurse) | ForEach {
     (Get-Content $_) | ForEach  {$_ -Replace '"maxParallelThreads":\s*([-\d]*)', "`"maxParallelThreads`": $MaxParallelThreads"} | Set-Content $_
}

Write-Output "Replaced $($configFiles.Count) occurrences."
