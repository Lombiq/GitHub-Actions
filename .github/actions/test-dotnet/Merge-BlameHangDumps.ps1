[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Configuration', Justification = 'The Configuration parameter is in use.')]
param ($Directory, $Configuration)

$rootDirectory = Resolve-Path $Directory
$blameHangDumpsName = 'BlameHangDumps'
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
