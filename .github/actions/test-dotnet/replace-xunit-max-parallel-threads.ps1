param ($MaxParallelThreads)

Write-Output "Replacing maxParallelThreads in xunit.runner.json files to $MaxParallelThreads."

$counter = 0

Get-ChildItem "*/**/xunit.runner.json" -Recurse | ForEach {
     $counter++
     (Get-Content $_) | ForEach  {$_ -Replace '"maxParallelThreads":\s*([-\d]*)', "`"maxParallelThreads`": $MaxParallelThreads"} | Set-Content $_
}

Write-Output "Replaced $counter occurrences."
