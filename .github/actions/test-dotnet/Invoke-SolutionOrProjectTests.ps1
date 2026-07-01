param (
    [string] $SolutionOrProject,
    [string] $Verbosity,
    [string] $Filter,
    [string] $Configuration,
    [string] $BlameHangTimeout,
    [string] $TestProcessTimeout,
    [boolean] $EnableDiagnosticMode,
    [boolean] $ShowTimeRemaining)

function Write-GitHub
{
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,
        [switch] $Warning,
        [switch] $Notice)

    $mode = 'error'

    if ($Warning) { $mode = 'warning' }
    if ($Notice) { $mode = 'notice' }

    # Write-Host is used because these messages always have to go to the workflow runner's virtual console.
    Write-Host "::$mode::$Message"
}

# This setting lets us always display the information stream without needing to add the "-InformationAction Continue" to
# every call. This is not best practice for general PowerShell scripts, but makes sense for scripts made for GHA.
$InformationPreference="Continue"

# First, we globally set test configurations using environment variables. Then acquire the list of all test projects
# (excluding the two test libraries) and then run each until one fails or all concludes. If a test fails, the output is
# sanitized from unnecessary diagnostics messages from chromedriver if the output doesn't already contain groupings,
# then it wraps them in "::group::<project name>". If there are already groupings, then it is not possible to nest them
# (https://github.com/actions/runner/issues/802) so that's omitted. The groupings make the output collapsible region on
# the Actions web UI. Note that we use bash to output the log using bash to avoid pwsh wrapping the output to the
# default buffer width.

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

if ($SolutionOrProject -imatch '\.slnx?$')
{
    $solutionName = [System.IO.Path]::GetFileNameWithoutExtension($SolutionOrProject)
    $solutionDirectory = [System.IO.Path]::GetDirectoryName($SolutionOrProject)

    Write-Information "Running tests for the `"$SolutionOrProject`" solution."
    Write-Information 'Gathering test projects.'

    $tests = @()
    dotnet sln $SolutionOrProject list |
        Select-Object -Skip 2 |
        Select-String '\.Tests\.' |
        Select-String -NotMatch 'Lombiq.Tests.UI.csproj' |
        Select-String -NotMatch 'Lombiq.Tests.csproj' |
        ForEach-Object {
            $absolutePath = Resolve-Path -Path (Join-Path -Path $solutionDirectory -ChildPath $PSItem)

            # While the test projects are run individually, passing in the solution name and solution dir via the
            # conventional MSBuild properties allows build customization.
            $switches = @(
                "--configuration:$Configuration"
                '--no-build'
                '--list-tests'
                "--verbosity:$Verbosity"
                "-p:SolutionName=""$solutionName"""
                "-p:SolutionDir=""$solutionDirectory"""
                $absolutePath
            )

            # Show the current command for easier debugging if run fails here.
            Write-Information "Discovering tests with ``dotnet test $switches``."

            # Without Out-String, Contains() below won't work for some reason.
            $output = dotnet test @switches 2>&1 | Out-String -Width 9999

            if ($LASTEXITCODE -ne 0)
            {
                Write-GitHub "dotnet test failed for the project `"$absolutePath`" with the following output:`n$output"
                exit 1
            }

            if (-not [string]::IsNullOrEmpty($output) -and $output.Contains('The following Tests are available'))
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
    Write-Information "Running tests for the `"$SolutionOrProject`' project."
    $tests = @($SolutionOrProject)
}
else
{
    Write-Error "The `"$SolutionOrProject`" is not a solution or project file."
    exit 1
}

if ($tests.Length -eq 0)
{
    Write-GitHub -Warning "No actionable tests were found."
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

function StartProcessAndWaitForExit($Switches, $Test, $Timeout = -1)
{
    # This is executed in a separate proecess so no variables or settings come through except what's copied over in the
    # "$args" automatic variable. Only Write-Output should be used here, so "Receive-Job" can reliably capture it.
    $block = {
        Write-Output "StartProcessAndWaitForExitProcessId:$PID"

        $switches = $args[0]
        $test = $args[1]
        dotnet test @switches $test 2>&1

        if ($LASTEXITCODE -ne 0)
        {
            Write-Output "::error::dotnet test failed for the project `"$test`"."
        }
    }


    $processId = -1
    $hasTestRunSuccessfully = $false
    $stopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $job = Start-Job -ScriptBlock $block -ArgumentList $Switches, $Test
    
    while ($job.HasMoreData -or $job.JobStateInfo.State -eq [System.Management.Automation.JobState]::Running)
    {
        Receive-Job $job | Tee-Object -Variable line | Out-Host

        if ("$line".StartsWith('StartProcessAndWaitForExitProcessId:'))
        {
            $processId = [int]("$line".Split('StartProcessAndWaitForExitProcessId:')[1].Split()[0])
        }

        if ("$line".Contains('Test Run Successful.'))
        {
            $hasTestRunSuccessfully = $true
        }

        if ("$line".Contains('::error::'))
        {
            $hasTestRunSuccessfully = $false
            break
        }
        
        if ($Timeout -gt 0)
        {
            if ($stopWatch.Elapsed.TotalMilliseconds -gt $Timeout)
            {
                Write-GitHub -Warning "The process for ``dotnet test $Switches $Test`` didn't exit in $Timeout milliseconds."
                $hasTestRunSuccessfully = $false
                break
            }

            if ($ShowTimeRemaining)
            {
                Write-Information "Time Remaining: $([Math]::Ceiling(($Timeout - $stopWatch.Elapsed.TotalMilliseconds) / 1000))s"
            }
        }

        Start-Sleep -Seconds 1
    }

    if (-not $hasTestRunSuccessfully)
    {
        Failed -Job $job -ProcessId $processId -Switches $Switches -Test $Test
    }

    return $hasTestRunSuccessfully
}

foreach ($test in $tests)
{
    # This could benefit from grouping, above the level of the potential groups created by the tests (the Lombiq UI
    # Testing Toolbox adds per-test groups too). However, there's no nested grouping, see
    # https://github.com/actions/runner/issues/1477. See the c341ef145d2a0898c5900f64604b67b21d2ea5db commit for a
    # nested grouping implementation.

    Write-Information "Starting to execute tests from the $test project."

    $dotnetTestSwitches = @(
        '--configuration', $Configuration
        '--nologo',
        '--no-build',
        '--logger', 'trx;LogFileName=test-results.trx'
        # This is for xUnit ITestOutputHelper, see https://xunit.net/docs/capturing-output.
        '--logger', 'console;verbosity=detailed'
        '--verbosity', $Verbosity
    )

    if ($BlameHangTimeout)
    {
        $dotnetTestSwitches += ('--blame-hang-timeout', $BlameHangTimeout, '--blame-hang-dump-type', 'full')
    }

    if ($Filter)
    {
        $dotnetTestSwitches += ('--filter', "'$Filter'")
    }

    if ($EnableDiagnosticMode)
    {
        $dotnetTestSwitches += ('--diag', 'DiagnosticLogs/dotnet-test.log')
    }

    Write-Information "Starting testing with ``dotnet test $dotnetTestSwitches $test``."

    $success = StartProcessAndWaitForExit -Switches $dotnetTestSwitches -Test $test -Timeout $TestProcessTimeout

    if ($success)
    {
        Write-GitHub -Notice "Test successful: $test"
        continue
    }

    Write-GitHub "Test failed: $test"
    exit 100
}
