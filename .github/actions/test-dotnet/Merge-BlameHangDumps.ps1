param ($Directory)

$directoryName = (Resolve-Path $Directory)
$dumpDirectory = (New-Item -Type Directory -Path $directoryName -Name 'BlameHangDumps')

Get-ChildItem $Directory -Recurse |
    Where-Object { ($PSItem.Name -like 'Sequence_*.xml') -or ($PSItem.Name -like '*_hangdump.dmp') } |
    ForEach-Object {
        $destinationDirectory = (Join-Path -Path $dumpDirectory.FullName -ChildPath ([System.IO.Path]::GetRelativePath($directoryName, $PSItem.Directory.FullName)))
        if (!(Test-Path -Path $destinationDirectory))
        {
            New-Item -Type Directory -Path $destinationDirectory
        }

        Copy-Item -Path $PSItem.FullName -Destination $destinationDirectory
    }
