# Get the latest version of the package.
$latestPackage = Find-Package -Name Microsoft.SourceLink.GitHub -ProviderName NuGet | Sort-Object Version -Descending | Select-Object -First 1
$latestVersion = $latestPackage.Version

# Find solution file.
$solutionFile = Get-ChildItem -Path . -Filter *.sln -Recurse | Select-Object -First 1

if ($null -eq $solutionFile)
{
    # Solution file not found. Looking for project files.
    Write-Output "Solution file not found. Looking for project files."
    $projects = Get-ChildItem -Path . -Recurse | Where-Object { $_.Extension -eq ".csproj" -or $_.Extension -eq ".fsproj" }
}
else
{
    # Solution file found. Extracting project files.
    Write-Output "Solution file found: $($solutionFile.FullName). Extracting project files."
    $projectPaths = dotnet sln $($solutionFile.FullName) list
    $projects = $projectPaths | ForEach-Object { Get-Item $_ }
}

foreach ($project in $projects)
{
    Write-Output "Processing project: $($project.FullName)"

    # Load the project file as XML.
    $projectXml = [xml](Get-Content $project.FullName)

    # Define the xmlns to access the elements in the csproj.
    $ns = New-Object Xml.XmlNamespaceManager $projectXml.NameTable
    $ns.AddNamespace("ns", $projectXml.DocumentElement.NamespaceURI)

    # Create a new ItemGroup.
    $itemGroup = $projectXml.CreateElement("ItemGroup", $projectXml.DocumentElement.NamespaceURI)

    # Create a new PackageReference.
    $packageNode = $projectXml.CreateElement("PackageReference", $projectXml.DocumentElement.NamespaceURI)
    $packageNode.SetAttribute("Include", "Microsoft.SourceLink.GitHub")
    $packageNode.SetAttribute("Version", $latestVersion)

    # Add the package to the ItemGroup.
    $itemGroup.AppendChild($packageNode)

    # Add the new ItemGroup to the project.
    $projectXml.Project.AppendChild($itemGroup)

    # Save the changes back to the .csproj file.
    $projectXml.Save($project.FullName)
}
