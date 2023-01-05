param ($Solution, $Verbosity, $Filter, $Configuration)

# Note that this script will only find tests if they were previously build in Release mode.

# First, we globally set test configurations using environment variables. Then acquire the list of all test projects
# (excluding the two test libraries) and then run each until one fails or all concludes. If a test fails, the output is
# sanitized from unnecessary diagnostics messages from chromedriver if the output doesn't already contain groupings,
# then it wraps them in "::group::<project name>". If there are already groupings, then it is not possible to nest them
# (https://github.com/actions/runner/issues/802) so that's omitted. The groupings make the output collapsible region on
# the Actions web UI. Note that we use bash to output the log using bash to avoid pwsh wrapping the output to the
# default buffer width.

$ConnectionStringSuffix = ";MultipleActiveResultSets=True;Connection Timeout=60;ConnectRetryCount=15;ConnectRetryInterval=5;TrustServerCertificate=true;Encrypt=false";
if ($Env:RUNNER_OS -eq "Windows")
{
    $Env:Lombiq_Tests_UI__SqlServerDatabaseConfiguration__ConnectionStringTemplate =
        "Server=.\SQLEXPRESS;Database=LombiqUITestingToolbox_{{id}};Integrated Security=True" + $ConnectionStringSuffix
}
else
{
    $Env:Lombiq_Tests_UI__SqlServerDatabaseConfiguration__ConnectionStringTemplate =
        "Server=.;Database=LombiqUITestingToolbox_{{id}};User Id=sa;Password=Password1!" + $ConnectionStringSuffix

    $Env:Lombiq_Tests_UI__DockerConfiguration__ContainerName = "sql2019"
}

$Env:Lombiq_Tests_UI__BrowserConfiguration__Headless = "true"

# We assume that the solution was built in Release configuration. If the tests need to be built in Debug configuration,
# as they should, we need to first build them, but not restore. Otherwise, the Release tests are already built, so we
# don't need to build them here.
$optOut = $Configuration -eq "Debug" ? "--no-restore" : "--no-build"

$tests = dotnet sln $Solution list |
    Select-Object -Skip 2 |
    Select-String "\.Tests\." |
    Select-String -NotMatch "Lombiq.Tests.UI.csproj" |
    Select-String -NotMatch "Lombiq.Tests.csproj"

Write-Output "Starting to execute tests from $($tests.Length) projects."

foreach ($test in $tests)
{
    Write-Output "Starting to execute tests from the $test project."
    dotnet test --configuration $Configuration --list-tests --verbosity $Verbosity $test
}
