param ($Directory)

New-Item -Type Directory "$Directory/FailureDumps"

$testDirectory = "$Directory/test"
$rootDirectory = (Test-Path -Path $testDirectory) ? $testDirectory : $Directory

Get-ChildItem $rootDirectory -Recurse |
    Where-Object { $PSItem.Name -eq 'FailureDumps' } |
    ForEach-Object { $PSItem.GetDirectories() } |
    ForEach-Object { Move-Item $PSItem.FullName "$Directory/FailureDumps/$($PSItem.Name)" }
