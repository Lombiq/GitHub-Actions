param ($Directory)

New-Item -Type Directory "$Directory/FailureDumps"

$rootDirectory = (Test-Path -Path "$Directory/test") ? "$Directory/test" : $Directory

Get-ChildItem $rootDirectory -Recurse |
    ? { $_.Name -eq 'FailureDumps' } |
    % { $_.GetDirectories() } |
    % { Move-Item $_.FullName "$Directory/FailureDumps/${_.Name}" }
