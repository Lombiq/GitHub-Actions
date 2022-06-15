param ($Verbosity, $EnableCodeAnalysis)

npm install pnpm -g

if (Test-Path src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj)
{
    Write-Output "Gulp Extensions found. Building it first because it requires it."
    dotnet build src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj --configuration Release --verbosity $Verbosity
}
else
{
    Write-Output "No Gulp Extensions found."
}

$buildSwitches = @(
    "--configuration",
    "Release",
    "-warnaserror",
    "-p:TreatWarningsAsErrors=true",
    "-p:RunAnalyzersDuringBuild=$EnableCodeAnalysis",
    "-nologo",
    "-consoleLoggerParameters:NoSummary",
    "-verbosity:$Verbosity"
)

dotnet build (Get-ChildItem *.sln).FullName @buildSwitches