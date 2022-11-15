param ($Directory)

New-Item -Type Directory "$Directory/FailureDumps"

$testDirectory = "$Directory/test"
$rootDirectory = (Test-Path -Path $testDirectory) ? $testDirectory : $Directory

Get-ChildItem $rootDirectory -Recurse |
    Where-Object { $_.Name -eq 'FailureDumps' } |
    ForEach-Object { $_.GetDirectories() } |
    ForEach-Object { Move-Item $_.FullName "$Directory/FailureDumps/${_.Name}" }
