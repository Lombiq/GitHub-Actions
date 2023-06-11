param ($Solution, $Verbosity, $Filter, $Configuration, $BlameHangTimeout)

# Note that this script will only find tests if they were previously build in Release mode.

# First, we globally set test configurations using environment variables. Then acquire the list of all test projects
# (excluding the two test libraries) and then run each until one fails or all concludes. If a test fails, the output is
# sanitized from unnecessary diagnostics messages from chromedriver if the output doesn't already contain groupings,
# then it wraps them in "::group::<project name>". If there are already groupings, then it is not possible to nest them
# (https://github.com/actions/runner/issues/802) so that's omitted. The groupings make the output collapsible region on
# the Actions web UI. Note that we use bash to output the log using bash to avoid pwsh wrapping the output to the
# default buffer width.

$connectionStringSuffix = @(
    ';MultipleActiveResultSets=True;Connection Timeout=60;ConnectRetryCount=15;ConnectRetryInterval=5;Encrypt=false;'
    'TrustServerCertificate=true'
) -join ''
if ($Env:RUNNER_OS -eq 'Windows')
{
    $connectionStringStem = 'Server=.\SQLEXPRESS;Database=LombiqUITestingToolbox_{{id}};Integrated Security=True'
}
else
{
    $connectionStringStem = 'Server=.;Database=LombiqUITestingToolbox_{{id}};User Id=sa;Password=Password1!'

    $Env:Lombiq_Tests_UI__DockerConfiguration__ContainerName = 'sql2019'
}

$Env:Lombiq_Tests_UI__SqlServerDatabaseConfiguration__ConnectionStringTemplate = $connectionStringStem + $connectionStringSuffix
$Env:Lombiq_Tests_UI__BrowserConfiguration__Headless = 'true'

# We assume that the solution was built in Release configuration. If the tests need to be built in Debug configuration,
# as they should, we need to first build them, but not restore. Otherwise, the Release tests are already built, so we
# don't need to build them here.
$optOut = $Configuration -eq 'Debug' ? '--no-restore' : '--no-build'

$solutionName = [System.IO.Path]::GetFileNameWithoutExtension($Solution)

Write-Output "Running tests for the $Solution solution."

$tests = dotnet sln $Solution list |
    Select-Object -Skip 2 |
    Select-String '\.Tests\.' |
    Select-String -NotMatch 'Lombiq.Tests.UI.csproj' |
    Select-String -NotMatch 'Lombiq.Tests.csproj' |
    Where-Object {
        # While the test projects are run individually, passing in the solution name via the conventional MSBuild #
        # property allows build customization.
        $switches = @(
            $optOut
            "--configuration:$Configuration"
            '--list-tests'
            "--verbosity:$Verbosity"
            "-p:SolutionName=""$solutionName"""
        )
        # Without Out-String, Contains() below won't work for some reason.
        $output = dotnet test @switches $PSItem 2>&1 | Out-String -Width 9999

        if ($LASTEXITCODE -ne 0)
        {
            $errorMessage = "dotnet test failed for the project $PSItem with the following output:`n$output"
            throw $errorMessage
        }

        -not [string]::IsNullOrEmpty($output) -and $output.Contains('The following Tests are available')
    }

Set-GitHubOutput 'test-count' $tests.Length

Write-Output "Starting to execute tests from $($tests.Length) projects."

foreach ($test in $tests)
{
    # This could benefit from grouping, above the level of the potential groups created by the tests (the Lombiq UI
    # Testing Toolbox adds per-test groups too). However, there's no nested grouping, see
    # https://github.com/actions/runner/issues/1477. See the # c341ef145d2a0898c5900f64604b67b21d2ea5db commit for a
    # nested grouping implementation.

    Write-Output "Starting to execute tests from the $test project."

    $dotnetTestSwitches = @(
        $optOut,
        '--configuration', $Configuration
        '--nologo',
        '--logger', 'trx;LogFileName=test-results.trx'
        # This is for xUnit ITestOutputHelper, see https://xunit.net/docs/capturing-output.
        '--logger', 'console;verbosity=detailed'
        '--verbosity', $Verbosity
        $BlameHangTimeout ? ('--blame-hang-timeout', $BlameHangTimeout, '--blame-hang-dump-type', 'full') : ''
        $Filter ? '--filter', $Filter : ''
        $test
    )

    Write-Output "Starting testing with ``dotnet test $($dotnetTestSwitches -join ' ')``."

    dotnet test @dotnetTestSwitches 2>&1 |
        Where-Object { $PSItem -notlike '*Connection refused [[]::ffff:127.0.0.1[]]*' -and $PSItem -notlike '*ChromeDriver was started successfully*' }

    if ($?)
    {
        Write-Output "Test successful: $test"
        continue
    }

    Write-Output "Test failed: $test"

    exit 100
}
