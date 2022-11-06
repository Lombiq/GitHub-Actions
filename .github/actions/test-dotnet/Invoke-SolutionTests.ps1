param ($Verbosity)

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

$tests = dotnet sln list |
    Select-Object -Skip 2 |
    Select-String "\.Tests\." |
    Select-String -NotMatch "Lombiq.Tests.UI.csproj" |
    Select-String -NotMatch "Lombiq.Tests.csproj" |
    ? {
        $result = dotnet test --no-restore --list-tests --verbosity $Verbosity $_ 2>&1 | Out-String -Width 9999
        -not [string]::IsNullOrEmpty($result) -and $result.Contains("The following Tests are available")
    }

foreach ($test in $tests) {
    dotnet test -c Release --no-restore --no-build --nologo --logger "trx;LogFileName=test-results.trx" --verbosity $Verbosity $test 2>&1 >test.out

    if ($?)
    {
        Write-Output "Test Successful: $test"
        continue
    }

    $needsGrouping = (Select-String "::group::" test.out).Length -eq 0

    if ($needsGrouping) { Write-Output "::group::Test Failed: $test" }

    bash -c "cat test.out | grep -v 'Connection refused \[::ffff:127.0.0.1\]' | grep -v 'ChromeDriver was started successfully'"

    if ($needsGrouping) { Write-Output "::endgroup::" }

    exit 100
}
