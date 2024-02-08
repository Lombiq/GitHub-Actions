# Register NuGet.org as a package source since GitHub runners don't necessarily have it by default.
$existingSource = Get-PackageSource -Name NuGet.org -ErrorAction SilentlyContinue

if (-not $existingSource)
{
    Register-PackageSource -Name NuGet.org -Location https://api.nuget.org/v3/index.json -ProviderName NuGet
}
else
{
    Write-Output "Package source for NuGet.org is already registered."
}

# Get the latest version of the package.
$latestPackage = Find-Package -Name Microsoft.SourceLink.GitHub -Source NuGet.org | Sort-Object Version -Descending | Select-Object -First 1
$latestVersion = $latestPackage.Version

# Find solution file.
$solutionFile = Get-ChildItem -Path . -Filter *.sln -Recurse | Select-Object -First 1

if ($null -eq $solutionFile)
{
    # Solution file not found. Looking for project files.
    Write-Output 'Solution file not found. Looking for project files.'
    $projectFiles = Get-ChildItem -Path . -Recurse | Where-Object { $PSItem.Extension -eq '.csproj' -or $PSItem.Extension -eq '.fsproj' }
}
else
{
    # Solution file found. Extracting project files.
    Write-Output "Solution file found: $($solutionFile.FullName). Extracting project files."
    $projectPaths = dotnet sln $($solutionFile.FullName) list | Select-Object -Skip 2
    $projectFiles = $projectPaths | ForEach-Object { Get-Item -Path $PSItem }
}

foreach ($projectFile in $projectFiles)
{
    Write-Output "Processing project: $($projectFile.FullName)"

    # Load the project file as XML.
    $projectXml = [xml](Get-Content -Path $projectFile.FullName)

    # Define the xmlns to access the elements in the csproj.
    $namespaceManager = New-Object Xml.XmlNamespaceManager $projectXml.NameTable
    $namespaceManager.AddNamespace('ns', $projectXml.DocumentElement.NamespaceURI)

    # Create a new ItemGroup.
    $itemGroup = $projectXml.CreateElement('ItemGroup', $projectXml.DocumentElement.NamespaceURI)

    # Create a new PackageReference.
    $packageNode = $projectXml.CreateElement('PackageReference', $projectXml.DocumentElement.NamespaceURI)
    $packageNode.SetAttribute('Include', 'Microsoft.SourceLink.GitHub')
    $packageNode.SetAttribute('Version', $latestVersion)

    # Add the package to the ItemGroup.
    $itemGroup.AppendChild($packageNode)

    # Add the new ItemGroup to the project.
    $projectXml.Project.AppendChild($itemGroup)

    # Save the changes back to the .csproj file.
    $projectXml.Save($projectFile.FullName)
}
