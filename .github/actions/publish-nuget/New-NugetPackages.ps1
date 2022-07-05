param([array] $Arguments)

foreach ($project in (dotnet sln list | Select-Object -Skip 2 | % { Get-ChildItem $_ }))
{
    Push-Location $project.Directory

    $nuspecFile = (Get-ChildItem *.nuspec).Name
    if ($nuspecFile.Count -eq 1)
    {
        dotnet pack $project -p:NuspecFile="$nuspecFile" @Arguments
    }
    else
    {
        dotnet pack $project @Arguments
    }

    Pop-Location
}
