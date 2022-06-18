param ($Verbosity, $EnableCodeAnalysis, $Version)

Write-Output "Env var test: $Env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE - $Env:DOTNET_CLI_TELEMETRY_OPTOUT - $Env:SOMETHING_ELSE_JUST_FOR_ME - $Env:SOMETHING_ELSE_JUST_FOR_ME2"

# Notes on build switches that aren't self-explanatory:
# - /p:Retries and /p:RetryDelayMilliseconds are to retry builds if it fails the first time due to random locks.
# - -warnAsMessage:MSB3026 is also to prevent random locks along the lines of "warning MSB3026: Could not copy dlls
#   errors." from breaking the build (since we treat warnings as errors).

$buildSwitches = @(
    "--configuration:Release",
    "-warnaserror",
    "-p:TreatWarningsAsErrors=true",
    "-p:RunAnalyzersDuringBuild=$EnableCodeAnalysis",
    "-nologo",
    "-consoleLoggerParameters:NoSummary",
    "-verbosity:$Verbosity",
    "/p:Retries=4",
    "/p:RetryDelayMilliseconds=1000",
    "-warnAsMessage:MSB3026",
    "/p:Version=$Version"
)

Write-Output ".NET version number: $Version"

if (Test-Path src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj)
{
    Write-Output "Gulp Extensions found. Building it first because it needs to be explicitly built before the solution."

    dotnet build src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj @buildSwitches
}

Write-Output "Building solution."

dotnet build (Get-ChildItem *.sln).FullName @buildSwitches
