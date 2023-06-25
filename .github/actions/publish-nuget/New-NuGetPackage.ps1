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

<#
.SYNOPSIS
    Updates the given project file with a GetPropertyValue target to retrieve MSBuild properties in a way that
    Directory.Build.props files also take effect, then retrieves the property.
#>
function Get-ProjectProperty
{
    param (
        [string] $ProjectFilePath,
        [string] $PropertyName
    )

    try
    {
        $projectFileContent = Get-Content $ProjectFilePath -ErrorAction Stop

        $newTarget = @"
  <Target Name="GetPropertyValue">
    <Message Importance="High" Text="---Get-ProjectProperty---`$($PropertyName)---Get-ProjectProperty---" />
  </Target>
"@

        # Insert the new target XML string just before the closing </Project> tag.
        $updatedProjectFileContent = $projectFileContent -replace '</Project>', "$newTarget`r`n</Project>"

        # Write the updated content to a new temporary project file.
        $extension = (Get-Item $ProjectFilePath).Extension
        $temporaryProjectFilePath = $ProjectFilePath -replace "\$extension`$", ".GetProperty$extension"
        Set-Content $temporaryProjectFilePath $updatedProjectFileContent -ErrorAction Stop

        $buildOutput = dotnet msbuild $temporaryProjectFilePath /nologo /v:minimal /p:DesignTimeBuild=true /p:BuildProjectReferences=false /t:GetPropertyValue

        # Removing the temporary file.
        Remove-Item $temporaryProjectFilePath

        return [string]::IsNullOrEmpty($buildOutput) ? '' : $buildOutput.Trim().Split("---Get-ProjectProperty---")[1]
    }
    catch
    {
        Write-Error "::error::Failed to add the GetPropertyValue target: $($_.Exception.Message)."
    }
}

$projects = (Test-Path *.sln) ? (dotnet sln list | Select-Object -Skip 2 | Get-Item) : (Get-ChildItem *.csproj)

foreach ($project in $projects)
{
    Write-Output "Packing $($project.Name)..."

    $isPackableProperty = Get-ProjectProperty -ProjectFilePath  $project -PropertyName 'IsPackable'
    $isPackable = [string]::IsNullOrEmpty($isPackableProperty) -or $isPackableProperty -eq 'true'

    # Silently skip project if the project file has <IsPackable>false</IsPackable>.
    if (-not $isPackable)
    {
        Write-Output "Skipping $($project.Name) because it has <IsPackable>false</IsPackable>."
        continue
    }

    # Warn and skip if the project doesn't specify a package license file.
    $packageLicenseFileProperty = Get-ProjectProperty -ProjectFilePath  $project -PropertyName 'PackageLicenseFile'
    if ([string]::IsNullOrEmpty($packageLicenseFileProperty))
    {
        Write-Output ("::warning file=$($project.FullName)::Packing was skipped because $($project.Name) doesn't " +
            'have a <PackageLicenseFile> property. You can avoid this check by including the " +
            "<IsPackable>false</IsPackable> property.')
        continue
    }

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
        Write-Output "::error file=$($project.FullName)::dotnet pack failed for the project $($project.Name)."
        exit 1
    }

    Pop-Location
}
