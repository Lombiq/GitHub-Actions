[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Configuration', Justification = 'The Configuration parameter is in use.')]
param ($Directory, $Configuration)

$rootDirectory = Resolve-Path $Directory
$blameHangDumpsName = 'BlameHangDumps'
$dumpDirectory = New-Item -Type Directory -Path $rootDirectory -Name $blameHangDumpsName
$testDirectoryPath = Join-Path $Directory 'test'
$testDirectory = (Test-Path -Path $testDirectoryPath) ? (Resolve-Path $testDirectoryPath) : $rootDirectory

# Save dotnet --info output.
dotnet --info *> (Join-Path -Path $dumpDirectory.FullName -ChildPath 'dotnet.info')

function ItemFilter($Item, $TestConfiguration)
{
    if ($Item.IsContainer)
    {
        return $False
    }

    $allow = (($Item.Name -like 'Sequence_*.xml') -or ($Item.Name -like '*_hangdump.dmp'))
    if (-not ($allow -and $TestConfiguration))
    {
        $allow = ($Item.FullName -like "*$(Join-Path 'bin' $TestConfiguration)*" )
    }

    $allow
}

Get-ChildItem $testDirectory.Path -Recurse |
    Where-Object { ItemFilter -Item $PSItem -TestConfiguration $Configuration } |
    ForEach-Object {
        # To avoid recursion in dump directory.
        if ($PSItem.FullName.StartsWith($dumpDirectory.FullName) -or (-not $PSItem.Directory))
        {
            return
        }

        $relativePath = [System.IO.Path]::GetRelativePath($rootDirectory, $PSItem.Directory.FullName)
        $destinationDirectory = (Join-Path -Path $dumpDirectory.FullName -ChildPath $relativePath)
        if (-not (Test-Path -Path $destinationDirectory))
        {
            New-Item -Type Directory -Path $destinationDirectory
        }

        Copy-Item -Path $PSItem.FullName -Destination $destinationDirectory
    }
