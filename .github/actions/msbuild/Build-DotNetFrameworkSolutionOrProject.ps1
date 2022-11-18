param (
    [string] $SolutionOrProject,
    [string] $Verbosity,
    [string] $EnableCodeAnalysis,
    [string] $Version,
    [string] $Switches)

function ConvertTo-Array([string] $rawInput)
{
    $rawInput.Replace("`r", "").Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

Write-Output ".NET version number: $Version"

if (Test-Path src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj)
{
    Write-Output "::group::Gulp Extensions found. It needs to be explicitly built before the solution."

    # These need to be different than that of msbuild.
    $gulpBuildSwitches = ConvertTo-Array @"
    --configuration:Release
    --nologo
    --verbosity:$Verbosity
    --warnaserror
    --warnAsMessage:MSB3026
    --consoleLoggerParameters:NoSummary
    -p:TreatWarningsAsErrors=true
    -p:RunAnalyzersDuringBuild=$EnableCodeAnalysis
    -p:Retries=4
    -p:RetryDelayMilliseconds=1000
    -p:Version=$Version
"@

    $startTime = [DateTime]::Now
    dotnet build src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj @gulpBuildSwitches
    $endTime = [DateTime]::Now

    Write-Output ("Gulp Extensions build took {0:0.###} seconds." -f ($endTime - $startTime).TotalSeconds)
    Write-Output "::endgroup::"
}

# Notes on build switches that aren't self-explanatory:
# - -p:Retries and -p:RetryDelayMilliseconds are to retry builds if it fails the first time due to random locks.

$buildSwitches = ConvertTo-Array @"
    -p:Configuration=Release
    -restore
    --verbosity:$Verbosity
    --warnaserror
    -p:TreatWarningsAsErrors=true
    -p:RunAnalyzersDuringBuild=$EnableCodeAnalysis
    -p:Retries=4
    -p:RetryDelayMilliseconds=1000
    -p:Version=$Version
    $Switches
"@

Write-Output "Building solution or project with ``msbuild $SolutionOrProject $($buildSwitches -join " ")``."

msbuild $SolutionOrProject @buildSwitches

# Without this, if the msbuild command fails, then still the error wouldn't be surfaced.
if ($?)
{
    Write-Output "Build successful."
    continue
}

Write-Output "::error::Build failed. See the errors above in the build log."
exit 100

Close-DotNetBuildServers
