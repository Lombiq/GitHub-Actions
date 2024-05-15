[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Configuration', Justification = 'The Configuration parameter is in use.')]
param ($Directory, $Configuration)

$rootDirectory = Resolve-Path $Directory
$blameHangDumpsName = 'BlameHangDumps'
$testDirectoryPath = Join-Path $Directory 'test'
$testDirectory = (Test-Path -Path $testDirectoryPath) ? (Resolve-Path $testDirectoryPath) : $rootDirectory

$dumpCount = (Get-ChildItem -Filter '*_hangdump.dmp' -Recurse | Measure-Object).Count
Set-GitHubOutput 'dump-count' $dumpCount

if ($dumpCount -eq 0)
{
    # No dump files were found. Nothing to do.
    Exit
}

$dumpDirectory = New-Item -Type Directory -Path $rootDirectory -Name $blameHangDumpsName

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

        # The artifact directory can contain directories, that have ":" in the name of them on Ubuntu. However, this
        # causes an error in "actions/upload-artifact@v3.1.1".
        $destinationDirectory = (Join-Path -Path $dumpDirectory.FullName -ChildPath $relativePath) -replace ':', '_'
        if (-not (Test-Path -Path $destinationDirectory))
        {
            New-Item -Type Directory -Path $destinationDirectory
        }

        Move-Item -Path $PSItem.FullName -Destination $destinationDirectory
    }
