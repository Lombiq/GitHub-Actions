param ($Directory)

New-Item -Type Directory "$Directory/BlameHangDumps"

Get-ChildItem $Directory -Recurse |
    Where-Object { ($PSItem.Name -like 'Sequence_*.xml') -or ($PSItem.Name -like '*_hangdump.dmp') } |
    ForEach-Object { $PSItem.GetDirectories() } |
    ForEach-Object { Move-Item $PSItem.FullName "$Directory/BlameHangDumps/${_.Name}" }
