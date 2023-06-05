param ($Solution, $Verbosity, $Filter, $Configuration, $BlameHangTimeout, $TestProcessTimeout)

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

$tests = dotnet sln $Solution list |
    Select-Object -Skip 2 |
    Select-String '\.Tests\.' |
    Select-String -NotMatch 'Lombiq.Tests.UI.csproj' |
    Select-String -NotMatch 'Lombiq.Tests.csproj' |
    Where-Object {
        $result = dotnet test $optOut --configuration $Configuration --list-tests --verbosity $Verbosity $PSItem 2>&1 | Out-String -Width 9999
        -not [string]::IsNullOrEmpty($result) -and $result.Contains('The following Tests are available')
    }

Set-GitHubOutput 'test-count' $tests.Length

Write-Output "Starting to execute tests from $($tests.Length) projects."

function StartProcessAndWaitForExit($FileName, $Arguments, $Timeout = -1)
{
    $process = [System.Diagnostics.Process]@{
        StartInfo = @{
            FileName = 'pwsh'
            Arguments = "-c `"$FileName $Arguments 2>&1`""
            RedirectStandardOutput = $true
            RedirectStandardError = $true
            UseShellExecute = $false
            WorkingDirectory = Get-Location
        }
    }

    $output = New-Object System.Text.StringBuilder
    $eventArgs = @{
        Output = $output
        Process = $process
    }

    $stdoutEvent = Register-ObjectEvent $process -EventName OutputDataReceived -MessageData $eventArgs -Action {
        $Event.MessageData.Output.AppendLine($Event.SourceEventArgs.Data)
        Write-Host $Event.SourceEventArgs.Data
    }

    $stderrEvent = Register-ObjectEvent $process -EventName ErrorDataReceived -MessageData $eventArgs -Action {
        $Event.MessageData.Output.AppendLine($Event.SourceEventArgs.Data)
        Write-Host $Event.SourceEventArgs.Data
    }

    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()

    $process.WaitForExit($Timeout)
    if ($process.HasExited)
    {
        $exitCode = $process.ExitCode
    }
    else
    {
        Write-Output "The process $($process.Id) didn't exit in $Timeout seconds."

        Write-Output "Collecting a dump of the process $($process.Id)."
        dotnet-dump collect -p $process.Id --type Full -o "./dotnet-test-hang-dump-$($process.Id).dmp"

        Write-Output "Killing the process $($process.Id)."
        Stop-Process -Force -Id $process.Id
        if ($output.ToString() -Like '*Test Run Successful.*')
        {
            Write-Output "The process $($process.Id) was killed but the tests were successful."
            $exitCode = 0
        }
        else
        {
            $exitCode = -1
        }
    }

    Unregister-Event $stdoutEvent.Id
    Unregister-Event $stderrEvent.Id

    return @{
        Output = $output.ToString()
        ExitCode = $exitCode
    }
}

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

    $processResult = StartProcessAndWaitForExit 'dotnet' "test $($dotnetTestSwitches -join ' ')" $TestProcessTimeout
    if ($processResult.ExitCode -eq 0)
    {
        Write-Output "Test successful: $test"
        continue
    }

    Write-Output "Test failed: $test"

    exit 100
}
