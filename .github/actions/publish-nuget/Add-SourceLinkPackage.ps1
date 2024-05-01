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
    # Below we first prepare the project file by adding the NuGetBuild=true property to the top of it. This is needed
    # for dotnet add package which could otherwise fail due to conditions in the project file.
    # We don't use a Directory.Build.props file for this because the project might have one already, and then we'd need
    # to merge it anyway.

    # Load the project file as XML.
    $projectXml = [xml](Get-Content $projectFile)

    # Define the xmlns to access the elements in the csproj.
    $ns = New-Object Xml.XmlNamespaceManager $projectXml.NameTable
    $ns.AddNamespace('ns', $projectXml.DocumentElement.NamespaceURI)

    # Create a new NuGetBuild property in a new PropertyGroup.
    $propertyGroup = $projectXml.CreateElement('PropertyGroup', $projectXml.DocumentElement.NamespaceURI)
    $nuGetBuildNode = $projectXml.CreateElement('NuGetBuild', $projectXml.DocumentElement.NamespaceURI)
    $nuGetBuildNode.InnerText = 'true'
    $propertyGroup.AppendChild($nuGetBuildNode)

    # Add the new PropertyGroup to the project as the first node, to make sure that it's fully applied.
    $projectXml.Project.InsertBefore($propertyGroup, $projectXml.Project.FirstChild)

    # Save the changes back to the .csproj file.
    $projectXml.Save($projectFile)

    # We can't use --no-restore because not only would it skip checks, it'd also be incompatible with projects using
    # Central Package Management (https://learn.microsoft.com/en-us/nuget/consume-packages/central-package-management).
    # Unfortunately, this makes NuGet publishing a lot slower than using dotnet restore, and it's also more verbose
    # (without the ability to configure that verbosity).
    dotnet add $projectFile.FullName package 'Microsoft.SourceLink.GitHub' --source 'https://api.nuget.org/v3/index.json'

    # The NuGetBuild property mustn't remain in the project file.
    $projectXml = [xml](Get-Content $projectFile)
    $projectXml.Project.RemoveChild($projectXml.Project.FirstChild)
    $projectXml.Save($projectFile)
}

Write-Output 'SourceLink package added to all projects.'
