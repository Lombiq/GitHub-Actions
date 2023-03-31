<#
.SYNOPSIS
    Creates a NuGet package from each project in the sln file in the current directory.
.DESCRIPTION
    Uses "dotnet sln list" to get all projects in the current directory. This means the current directory must have
    exactly one sln file in it. Then calls "dotnet pack" for each csproj file with the provided arguments. If there is
    a nuspec file in the project's directory too, then it is used to generate the package description instead of the
    regular auto-generation.
.NOTES
    We go through the projects individually in a foreach loop, because the "-p:NuspecFile=" parameter can't be passed
    to a solution.
.EXAMPLE
    New-NugetPackage @("--configuration:Release", "--warnaserror")
    Calls "dotnet pack project.csproj --configuration:Release --warnaserror" on each project.
#>

param([array] $Arguments)

$projects = (Test-Path *.sln) ? (dotnet sln list | Select-Object -Skip 2 | Get-Item) : (Get-ChildItem *.csproj)

foreach ($project in $projects)
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

    if ($LASTEXITCODE -ne 0)
    {
        Write-Error "::error::dotnet pack failed for the project $($project.FullName)."
        exit 1
    }

    Pop-Location
}
