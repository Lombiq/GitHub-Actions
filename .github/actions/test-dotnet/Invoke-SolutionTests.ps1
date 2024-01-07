param ($Solution, $Verbosity, $Filter, $Configuration, $BlameHangTimeout, $TestProcessTimeout)

# Note that this script will only find tests if they were previously build in Release mode.

# First, we globally set test configurations using environment variables. Then acquire the list of all test projects
# (excluding the two test libraries) and then run each until one fails or all concludes. If a test fails, the output is
# sanitized from unnecessary diagnostics messages from chromedriver if the output doesn't already contain groupings,
# then it wraps them in "::group::<project name>". If there are already groupings, then it is not possible to nest them
# (https://github.com/actions/runner/issues/802) so that's omitted. The groupings make the output collapsible region on
# the Actions web UI. Note that we use bash to output the log using bash to avoid pwsh wrapping the output to the
# default buffer width.

if ($Env:RUNNER_OS -eq 'Windows')
{
    $connectionSecurity = 'Integrated Security=True'
}
else
{
    $connectionSecurity = 'User Id=sa;Password=Password1!'

    $Env:Lombiq_Tests_UI__DockerConfiguration__ContainerName = 'uitt-sqlserver'
}

$connectionString = @(
    'Server=.;Database=LombiqUITestingToolbox_{{id}}'
    $connectionSecurity
    'MultipleActiveResultSets=True;Connection Timeout=60;ConnectRetryCount=15;ConnectRetryInterval=5;Encrypt=false'
    'TrustServerCertificate=true'
) -join ';'

$Env:Lombiq_Tests_UI__SqlServerDatabaseConfiguration__ConnectionStringTemplate = $connectionString
$Env:Lombiq_Tests_UI__BrowserConfiguration__Headless = 'true'

$solutionName = [System.IO.Path]::GetFileNameWithoutExtension($Solution)
$solutionDirectory = [System.IO.Path]::GetDirectoryName($Solution)


Write-Output "Running tests for the $Solution solution."

$tests = dotnet sln $Solution list |
    Select-Object -Skip 2 |
    Select-String '\.Tests\.' |
    Select-String -NotMatch 'Lombiq.Tests.UI.csproj' |
    Select-String -NotMatch 'Lombiq.Tests.csproj' |
    Where-Object {
        # While the test projects are run individually, passing in the solution name and solution dir via the
        # conventional MSBuild properties allows build customization.
        $switches = @(
            "--configuration:$Configuration"
            '--list-tests'
            "--verbosity:$Verbosity"
            "-p:SolutionName=""$solutionName"""
            "-p:SolutionDir=""$solutionDirectory"""
        )

        # Without Out-String, Contains() below won't work for some reason.
        $output = dotnet test @switches $PSItem 2>&1 | Out-String -Width 9999

        if ($LASTEXITCODE -ne 0)
        {
            Write-Error "::error::dotnet test failed for the project $PSItem with the following output:`n$output"
            exit 1
        }

        -not [string]::IsNullOrEmpty($output) -and $output.Contains('The following Tests are available')
    }

Set-GitHubOutput 'test-count' $tests.Length
Set-GitHubOutput 'dotnet-test-hang-dump' 0

Write-Output "Starting to execute tests from $($tests.Length) project(s)."

function GetChildProcesses($Id)
{
    return Get-Process | Where-Object { $PSItem.Parent.Id -eq $Id }
}

function DumpProcess($Output, $RootProcess, $DumpRootPath, $Process)
{
    if (!$Process)
    {
        return
    }

    $output.AppendLine("::warning::Collecting a dump of the process $($Process.Id).")

    dotnet-dump collect -p $Process.Id --type Full -o "$DumpRootPath/dotnet-test-hang-dump-$($RootProcess.Id)-$($Process.Name)_$($Process.Id).dmp"
}

function DumpProcessTree($Output, $RootProcess, $DumpRootPath, $CurrentProcess)
{
    foreach ($child in GetChildProcesses -Id $CurrentProcess.Id)
    {
        DumpProcessTree -Output $Output -RootProcess $RootProcess -DumpRootPath $DumpRootPath -CurrentProcess $child
    }

    DumpProcess -Output $Output -RootProcess $RootProcess -DumpRootPath $DumpRootPath -Process $CurrentProcess
}

function KillProcessTree($Output, $Process)
{
    $Output.AppendLine("::warning::Killing the process $($Process.Name)($($Process.Id)).")

    foreach ($child in GetChildProcesses -Id $Process.Id)
    {
        KillProcessTree -Output $Output -Process $child
    }

    Stop-Process -Force -InputObject $Process
}

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
    $eventHandlerArgs = @{
        Output = $output
        Process = $process
    }

    $stdoutEvent = Register-ObjectEvent $process -EventName OutputDataReceived -MessageData $eventHandlerArgs -Action {
        $Event.MessageData.Output.AppendLine($Event.SourceEventArgs.Data)
    }

    $stderrEvent = Register-ObjectEvent $process -EventName ErrorDataReceived -MessageData $eventHandlerArgs -Action {
        $Event.MessageData.Output.AppendLine($Event.SourceEventArgs.Data)
    }

    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()

    $process.WaitForExit($Timeout)
    $hasExited = $process.HasExited
    if ($hasExited)
    {
        $exitCode = $process.ExitCode
    }
    else
    {
        $output.AppendLine("::warning::The process $($process.Id) didn't exit in $Timeout seconds.")

        $output.AppendLine("::warning::Collecting a dump of the process $($process.Id) tree.")
        $dumpRootPath = './DotnetTestHangDumps'
        New-Item -ItemType 'directory' -Path $dumpRootPath -Force | Out-Null

        $rootProcess = Get-Process -Id $process.Id
        DumpProcessTree -RootProcess $rootProcess -DumpRootPath $dumpRootPath -CurrentProcess $rootProcess

        Set-GitHubOutput 'dotnet-test-hang-dump' 1

        KillProcessTree -Output $output -Process $rootProcess
    }

    Unregister-Event $stdoutEvent.Id
    Unregister-Event $stderrEvent.Id

    return @{
        Output = $output.ToString()
        ExitCode = $exitCode
        HasExited = $hasExited
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
        '--configuration', $Configuration
        '--nologo',
        '--logger', '''trx;LogFileName=test-results.trx'''
        # This is for xUnit ITestOutputHelper, see https://xunit.net/docs/capturing-output.
        '--logger', '''console;verbosity=detailed'''
        '--verbosity', $Verbosity
        $BlameHangTimeout ? ('--blame-hang-timeout', $BlameHangTimeout, '--blame-hang-dump-type', 'full') : ''
        $Filter ? '--filter', $Filter : ''
        $test
    )

    Write-Output "Starting testing with ``dotnet test $($dotnetTestSwitches -join ' ')``."

    $processResult = StartProcessAndWaitForExit -FileName 'dotnet' -Arguments "test $($dotnetTestSwitches -join ' ')" -Timeout $TestProcessTimeout

    Write-Output $processResult.Output

    if ($processResult.ExitCode -eq 0 || (!$processResult.HasExited && $processResult.Output -Like '*Test Run Successful.*'))
    {
        if (!$processResult.HasExited)
        {
            Write-Output "::warning::The process $($process.Id) was killed but the tests were successful."
        }

        Write-Output "Test successful: $test"

        continue
    }

    Write-Output "Test failed: $test"

    exit 100
}
