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

# Create a temporary project file with the GetPropertyValue target to be able to retrieve MSBuild properties in a way
# that Directory.Build.props files also take effect.
$tempProjectFileContent = @"
<Project>
    <Target Name="GetPropertyValue">
        <Message Text="$$(PropertyName)" />
    </Target>
</Project>
"@
$tempProjectFilePath = [System.IO.Path]::GetTempFileName() + ".proj"
$tempProjectFileContent | Out-File -FilePath $tempProjectFilePath -Encoding utf8

$projects = (Test-Path *.sln) ? (dotnet sln list | Select-Object -Skip 2 | Get-Item) : (Get-ChildItem *.csproj)

foreach ($project in $projects)
{
    Write-Output "Packing $($project.Name)..."

    $isPackableProperty = dotnet msbuild $tempProjectFilePath /nologo /v:quiet /p:DesignTimeBuild=true /p:BuildProjectReferences=false /t:GetPropertyValue /p:PropertyName=IsPackable /p:CustomAfterMicrosoftCommonTargets=$project
    $isPackable = [string]::IsNullOrEmpty($isPackableProperty) -or $isPackableProperty -eq "true"

    # Silently skip project if the project file has <IsPackable>false</IsPackable>.
    if (-not $isPackable)
    {
        Write-Output "Skipping $($project.Name) because it has <IsPackable>false</IsPackable>."
        continue
    }

    # Warn and skip if the project doesn't specify a package license file.
    $packageLicenseFileProperty = dotnet msbuild $tempProjectFilePath /nologo /v:quiet /p:DesignTimeBuild=true /p:BuildProjectReferences=false /t:GetPropertyValue /p:PropertyName=PackageLicenseFile /p:CustomAfterMicrosoftCommonTargets=$project
    if (-not $isPackable -and [string]::IsNullOrEmpty($packageLicenseFileProperty)) {
        Write-Output ("::warning file=$($project.FullName)::Packing was skipped because $($project.Name) doesn't " +
            'have a <PackageLicenseFile> property. You can avoid this check by including the <IsPackable> property.')
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

# Delete the temporary project file.
Remove-Item -Path $tempProjectFilePath
