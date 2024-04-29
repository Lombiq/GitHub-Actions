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
    dotnet add $projectFile.FullName package 'Microsoft.SourceLink.GitHub' --source 'https://api.nuget.org/v3/index.json'
}
