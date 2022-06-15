param ($Verbosity, $EnableCodeAnalysis)

npm install pnpm -g

if (Test-Path src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj)
{
    dotnet build src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj --configuration Release --verbosity $Verbosity
}

$buildSwitches = @(
    '--configuration',
    'Release',
    '-warnaserror',
    '-p:TreatWarningsAsErrors=true',
    "-p:RunAnalyzersDuringBuild=$EnableCodeAnalysis",
    '-nologo',
    '-consoleLoggerParameters:NoSummary',
    '--verbosity' + $Verbosity
)

dotnet build (Get-ChildItem *.sln).FullName @buildSwitches