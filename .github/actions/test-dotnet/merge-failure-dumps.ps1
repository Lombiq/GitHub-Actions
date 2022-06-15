param ($directory)

New-Item -Type Directory "$directory/FailureDumps"
Get-ChildItem "$directory/test" -Recurse |
    ? { $_.Name -eq 'FailureDumps' } |
    % { $_.GetDirectories() } |
    % { Move-Item $_.FullName "$directory/FailureDumps/${_.Name}" }
