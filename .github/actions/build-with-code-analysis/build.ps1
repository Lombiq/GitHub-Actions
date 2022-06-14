npm install pnpm -g

if (Test-Path src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj)
{
    dotnet build src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj --configuration Release --verbosity ${{ inputs.build-verbosity }}
}

$buildSwitches = @(
    '--configuration',
    'Release',
    '-warnaserror',
    '-p:TreatWarningsAsErrors=true',
    '-p:RunAnalyzersDuringBuild=true',
    '-nologo',
    '-consoleLoggerParameters:NoSummary',
    '-verbosity:${{ inputs.build-verbosity }}'
)

dotnet build (Get-ChildItem *.sln).FullName @buildSwitches