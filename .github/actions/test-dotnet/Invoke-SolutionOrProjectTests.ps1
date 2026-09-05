param (
    [ValidateSet('Microsoft.Testing.Platform', 'VSTest')]
    [string] $TestPlatform = 'Microsoft.Testing.Platform',
    [string] $SolutionOrProject,
    [string] $Verbosity,
    [string] $Filter,
    [string] $Configuration,
    [string] $BlameHangTimeout,
    [string] $TestProcessTimeout,
    [string] $RebuildDirectory,
    [boolean] $EnableDiagnosticMode,
    [boolean] $ShowTimeRemainingUntilTimeout)

# This is a magic variable, setting it lets us always display the information stream without needing to add the
# "-InformationAction Continue" to every call. This is not best practice for general PowerShell scripts, but makes sense
# for scripts made for GHA.
$informationPreference = 'Continue'
$useMtp = $TestPlatform -eq 'Microsoft.Testing.Platform'
$SolutionOrProject = (Resolve-Path $SolutionOrProject).Path
Set-GitHubOutput 'test-count' 0
Set-GitHubOutput 'dotnet-test-hang-dump' 0

# Set test configuration through environment variables, identify test applications, then run each until one fails.
# Preserve the test output, including the UI Testing Toolbox's GitHub Actions groups and annotations.

if ($Env:RUNNER_OS -eq 'Windows')
{
    $server = '.\SQLEXPRESS'
    $connectionSecurity = 'Integrated Security=True'
}
else
{
    $server = '.'
    $connectionSecurity = 'User Id=sa;Password=Password1!'

    $Env:Lombiq_Tests_UI__DockerConfiguration__ContainerName = 'uitt-sqlserver'
}

$connectionString = @(
    "Server=$server"
    'Database=LombiqUITestingToolbox_{{id}}'
    $connectionSecurity
    'Connection Timeout=60'
    'ConnectRetryCount=15'
    'ConnectRetryInterval=5'
    'Encrypt=False'
    'TrustServerCertificate=True'
) -join ';'

$Env:Lombiq_Tests_UI__SqlServerDatabaseConfiguration__ConnectionStringTemplate = $connectionString
$Env:Lombiq_Tests_UI__BrowserConfiguration__Headless = 'true'

# Running dotnet test on individual projects when the whole solution is not built can have unforseen effects. It's the
# safest to build the solution or project target explicitly, then run "dotnet test" with the "--no-build" switch.
Write-Information "Building target with ``dotnet build --verbosity $Verbosity --configuration $Configuration $SolutionOrProject``."
dotnet build --verbosity $Verbosity --configuration $Configuration $SolutionOrProject

if ($LASTEXITCODE -ne 0)
{
    Write-Error "Failed to build `"$SolutionOrProject`"."
    exit 1
}

if ($RebuildDirectory -and (Test-Path -Path $RebuildDirectory))
{
    Write-Information "Rebuilding `"$RebuildDirectory`"."
    foreach ($project in (Get-ChildItem -Path $RebuildDirectory -Filter *.csproj -Recurse))
    {
        Write-Information "Rebuilding `"$project`" with `"dotnet build $project $buildSwitches`"."
        dotnet build $project @buildSwitches
    }
}
else
{
    Write-Information "No rebuild for `"$RebuildDirectory`"."
}

if ($SolutionOrProject -imatch '\.slnx?$')
{
    $solutionName = [System.IO.Path]::GetFileNameWithoutExtension($SolutionOrProject)
    $solutionDirectory = [System.IO.Path]::GetDirectoryName($SolutionOrProject)

    Write-Information "Running tests for the `"$SolutionOrProject`" solution."
    Write-Information 'Gathering test projects.'

    $tests = @()
    dotnet sln $SolutionOrProject list |
        Select-Object -Skip 2 |
        ForEach-Object {
            $absolutePath = (Resolve-Path -Path (Join-Path -Path $solutionDirectory -ChildPath $PSItem)).Path

            # Evaluate project properties instead of relying on project names or localized test runner output.
            $properties = dotnet msbuild $absolutePath "-p:Configuration=$Configuration" `
                '-getProperty:IsTestingPlatformApplication,IsTestProject' -verbosity:quiet | Out-String
            if ($LASTEXITCODE -ne 0)
            {
                Write-GitHub "Failed to evaluate test project properties for `"$absolutePath`"."
                exit 1
            }

            $properties = ($properties | ConvertFrom-Json).Properties
            if ($useMtp)
            {
                if ($properties.IsTestingPlatformApplication -eq 'true')
                {
                    $tests += $absolutePath
                }
                elseif ($properties.IsTestProject -eq 'true')
                {
                    Write-GitHub "The test project `"$absolutePath`" does not support Microsoft.Testing.Platform. Migrate it or use test-platform: VSTest."
                    exit 1
                }

                return
            }

            if ($properties.IsTestProject -ne 'true')
            {
                return
            }

            # While the test projects are run individually, passing in the solution name and solution dir via the
            # conventional MSBuild properties allows build customization.
            $switches = @(
                "--configuration:$Configuration"
                '--no-build'
                '--list-tests'
                "--verbosity:$Verbosity"
                "-p:SolutionName=""$solutionName"""
                "-p:SolutionDir=""$solutionDirectory"""
            )

            if ($Filter)
            {
                $switches += ('--filter', "$Filter")
            }

            # Show the current command for easier debugging if run fails here.
            Write-Information "Discovering tests with ``dotnet test $switches $absolutePath``."

            # Without Out-String, Contains() below won't work for some reason.
            $output = dotnet test @switches $absolutePath 2>&1 | Out-String -Width 9999

            if ($LASTEXITCODE -ne 0)
            {
                Write-GitHub "dotnet test failed for the project `"$absolutePath`" with the following output:`n$output"
                exit 1
            }

            if ($output -match 'The following Tests are available.*\n\s+[a-zA-Z0-9_]+\.')
            {
                Write-Information "Found some tests for `"$absolutePath`"."
                $tests += $absolutePath
            }
            else
            {
                Write-Information "No tests were found for `"$absolutePath`"."
            }
        }
}
elseif ($SolutionOrProject -like '*.csproj')
{
    Write-Information "Running tests for the `"$SolutionOrProject`" project."
    $tests = @($SolutionOrProject)
}
else
{
    Write-Error "The `"$SolutionOrProject`" is not a solution or project file."
    exit 1
}

if ($tests.Length -eq 0)
{
    Write-GitHub -Warning 'No actionable tests were found.'
    exit 0
}

Write-Information "Found tests in these projects: $tests"

Set-GitHubOutput 'test-count' $tests.Length
Set-GitHubOutput 'dotnet-test-hang-dump' 0

Write-Information "Starting to execute tests from $($tests.Length) $(($tests.Length -eq 1) ? 'project' : 'projects')."

function GetChildProcesses($Id)
{
    return Get-Process | Where-Object { $PSItem.Parent -and $PSItem.Parent.Id -eq $Id }
}

function MemDumpProcess($RootProcess, $DumpRootPath, $Process)
{
    Write-Information "Collecting a dump of the process $($Process.Id)."

    $outputFile = "$DumpRootPath/dotnet-test-hang-dump-$($RootProcess.Id)-$($Process.Parent.Id)_$($Process.Id)"
    $Process | Format-Table Id, SI, Name, Path, @{ Label = 'TotalRunningTime'; Expression = { (Get-Date) - $PSItem.StartTime } } > "$outputFile.log"
    dotnet-dump collect --process-id $Process.Id --type Full --output "$outputFile.dmp" 2>&1 >> "$outputFile.log"
}

function MemDumpProcessTree($RootProcess, $DumpRootPath, $CurrentProcess)
{
    foreach ($child in GetChildProcesses -Id $CurrentProcess.Id)
    {
        MemDumpProcessTree -RootProcess $RootProcess -DumpRootPath $DumpRootPath -CurrentProcess $child
    }

    MemDumpProcess -RootProcess $RootProcess -DumpRootPath $DumpRootPath -Process $CurrentProcess
}

function KillProcessTree($Process)
{
    Write-Information "Killing the process $($Process.ProcessName)($($Process.Id))."

    foreach ($child in GetChildProcesses -Id $Process.Id)
    {
        KillProcessTree -Process $child
    }

    Stop-Process -Force -InputObject $Process
}

function Failed($Job, $ProcessId, $Switches, $Test)
{
    $rootProcess = Get-Process -Id $ProcessId -ErrorAction Ignore
    if ($ProcessId -gt 0 -and $rootProcess)
    {
        Write-Information "Collecting a dump of the process $($rootProcess.Id) tree."

        $dumpRootPath = './DotnetTestHangDumps'
        New-Item -ItemType 'directory' -Path $dumpRootPath -Force | Out-Null

        MemDumpProcessTree -RootProcess $rootProcess -DumpRootPath $dumpRootPath -CurrentProcess $rootProcess

        Set-GitHubOutput 'dotnet-test-hang-dump' 1

        Stop-Job $Job
        KillProcessTree -Process $rootProcess
    }
    else
    {
        Stop-Job $Job
    }
}

function StartProcessAndWaitForExit($Switches, $Test, $Timeout, $ShowTimeRemainingUntilTimeout)
{
    # This is executed in a separate process so no variables or settings come through except what's copied over in the
    # "$args" automatic variable. Only Write-Output should be used here, so "Receive-Job" can reliably capture it.
    $block = {
        Write-Output "StartProcessAndWaitForExitProcessId:$PID"

        $argSwitches = $args[0]
        $argTest = $args[1]
        dotnet test @argSwitches 2>&1

        # Use the process exit code, not human-readable runner output, to determine success.
        Write-Output "DotnetTestExitCode:$LASTEXITCODE"

        if ($LASTEXITCODE -ne 0)
        {
            Write-Output "::error::dotnet test failed for the project `"$argTest`" (exit code: $LASTEXITCODE)."
        }
    }

    $processId = -1
    $hasTestRunSuccessfully = $false
    $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $job = Start-Job -ScriptBlock $block -ArgumentList $Switches, $Test

    while ($job.HasMoreData -or $job.JobStateInfo.State -eq [System.Management.Automation.JobState]::Running)
    {
        Receive-Job $job | Tee-Object -Variable line | Out-Host

        foreach ($outputLine in $line)
        {
            if ("$outputLine" -match '^StartProcessAndWaitForExitProcessId:(\d+)$')
            {
                $processId = [int]$Matches[1]
            }
            elseif ("$outputLine" -match '^DotnetTestExitCode:(\d+)$')
            {
                $hasTestRunSuccessfully = [int]$Matches[1] -eq 0
            }
        }

        if ($Timeout -gt 0)
        {
            if ($stopWatch.Elapsed.TotalMilliseconds -gt $Timeout)
            {
                Write-GitHub -Warning "The process for ``dotnet test $Switches $Test`` didn't exit in $Timeout milliseconds."
                $hasTestRunSuccessfully = $false
                break
            }

            if ($ShowTimeRemainingUntilTimeout)
            {
                Write-Information "Until timeout: $([Math]::Ceiling(($Timeout - $stopWatch.Elapsed.TotalMilliseconds) / 1000))s"
            }
        }

        Start-Sleep -Seconds 1
    }

    if (-not $hasTestRunSuccessfully)
    {
        Failed -Job $job -ProcessId $processId -Switches $Switches -Test $Test
    }

    Remove-Job $job

    return $hasTestRunSuccessfully
}

foreach ($test in $tests)
{
    # This could benefit from grouping, above the level of the potential groups created by the tests (the Lombiq UI
    # Testing Toolbox adds per-test groups too). However, there's no nested grouping, see
    # https://github.com/actions/runner/issues/1477. See the c341ef145d2a0898c5900f64604b67b21d2ea5db commit for a
    # nested grouping implementation.

    Write-Information "Starting to execute tests from the $test project."

    $switches = @(
        '--configuration', $Configuration
        '--no-build'
        '--verbosity', $Verbosity
    )

    if ($useMtp)
    {
        $switches += @(
            '--project', $test
            '--output', 'Detailed'
        )

        if ($EnableDiagnosticMode)
        {
            $switches += ('--diagnostic-output-directory', (Join-Path (Get-Location) 'DiagnosticLogs'))
        }

        $switches += @(
            '--'
            '--report-trx'
            '--report-gh'
            # UI tests already emit per-test groups; GitHub Actions doesn't support nested groups.
            '--report-gh-groups', 'off'
            '--show-stdout', 'all'
            '--show-stderr', 'all'
        )

        # A solution can contain empty test projects, or a filter can select no tests in some of its projects.
        # Explicit project runs still fail when no tests run. Other failures always retain their exit code.
        if ($SolutionOrProject -imatch '\.slnx?$')
        {
            $switches += ('--ignore-exit-code', '8')
        }

        if ($BlameHangTimeout)
        {
            $switches += ('--hangdump', '--hangdump-timeout', $BlameHangTimeout, '--hangdump-type', 'Full')
            $switches += ('--hangdump-filename', '{asm}_{tfm}_{pid}_hangdump.dmp')
        }

        if ($EnableDiagnosticMode)
        {
            $switches += '--diagnostic'
        }
    }
    else
    {
        $switches += @(
            $test
            '--nologo'
            '--logger', 'trx;LogFileName=test-results.trx'
            '--logger', 'console;verbosity=detailed'
        )

        if ($BlameHangTimeout)
        {
            $switches += ('--blame-hang-timeout', $BlameHangTimeout, '--blame-hang-dump-type', 'full')
        }

        if ($EnableDiagnosticMode)
        {
            $switches += ('--diag', 'DiagnosticLogs/dotnet-test.log')
        }
    }

    if ($Filter)
    {
        $switches += ('--filter', $Filter)
    }

    Write-Information "Starting testing with ``dotnet test $switches``."

    $success = StartProcessAndWaitForExit -Switches $switches -Test $test -Timeout $TestProcessTimeout -ShowTimeRemainingUntilTimeout $ShowTimeRemainingUntilTimeout

    if ($success)
    {
        Write-GitHub -Notice "Test successful: $test"
        continue
    }

    Write-GitHub "Test failed: $test"
    exit 100
}
