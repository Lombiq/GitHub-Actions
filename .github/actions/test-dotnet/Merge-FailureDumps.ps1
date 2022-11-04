param ($Directory)

New-Item -Type Directory "$Directory/FailureDumps"

$testDirectory = "$Directory/test"
$rootDirectory = (Test-Path -Path $testDirectory) ? $testDirectory : $Directory

Get-ChildItem $rootDirectory -Recurse |
    ? { $_.Name -eq 'FailureDumps' } |
    % { $_.GetDirectories() } |
    % { Move-Item $_.FullName "$Directory/FailureDumps/${_.Name}" }
