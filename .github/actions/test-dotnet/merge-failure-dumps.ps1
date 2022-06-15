param ($Directory)

New-Item -Type Directory "$Directory/FailureDumps"
Get-ChildItem "$Directory/test" -Recurse |
    ? { $_.Name -eq 'FailureDumps' } |
    % { $_.GetDirectories() } |
    % { Move-Item $_.FullName "$Directory/FailureDumps/${_.Name}" }
