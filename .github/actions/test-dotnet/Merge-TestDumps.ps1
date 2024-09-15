param ($Directory)

New-Item -Type Directory "$Directory/TestDumps"

$testDirectory = "$Directory/test"
$rootDirectory = (Test-Path -Path $testDirectory) ? $testDirectory : $Directory

Get-ChildItem $rootDirectory -Recurse |
    Where-Object { $PSItem.Name -eq 'TestDumps' } |
    ForEach-Object { $PSItem.GetDirectories() } |
    ForEach-Object { Move-Item $PSItem.FullName "$Directory/TestDumps/$($PSItem.Name)" }
