param(
    [string] $SolutionPath,
    [string[]] $ExcludedProjects
)

if ($ExcludedProjects.Count -gt 0)
{
    foreach ($projectPath in $ExcludedProjects)
    {
        Write-Output "dotnet sln '$SolutionPath' remove '$projectPath'"
        dotnet sln $SolutionPath remove $projectPath
    }
}

$consolidateParams = @(
    '--solutions', $SolutionPath
    '--excludedVersionsRegex', $Env:ExcludeVersionRegex
)

$output = dotnet consolidate @consolidateParams 2>&1 | Out-String -Width 9999

Write-Output $output

# An error in the options won't cause dotnet-consolidate to return a non-zero exit code, so we need to check the output
# for errors.
if ($LASTEXITCODE -ne 0 -or $output.Contains('ERROR(S)'))
{
    Write-Error '::error::dotnet consolidate failed with the above errors.'
}
# if there wasn't an error and we have removed at least one project form the solution, reset the repo to restore the
# removed projects.
elseif ($ExcludedProjects.Count -gt 0)
{
    git reset --hard
    git submodule update --init
}