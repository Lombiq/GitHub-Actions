$errorActionPreference = 'Stop'
$actionPath = (Resolve-Path "$PSScriptRoot/..").Path
$repositoryPath = (Resolve-Path "$PSScriptRoot/../../../..").Path
$artifactPath = Join-Path $PSScriptRoot "artifacts/$([Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $artifactPath -Force | Out-Null

$savedEnvironment = @{}

foreach ($name in @('PATH', 'GITHUB_ACTIONS', 'GITHUB_OUTPUT', 'GITHUB_STEP_SUMMARY', 'GITHUB_WORKSPACE', 'LGHA_TEST_FAILURE'))
{
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
}

function Assert-True($Condition, $Message)
{
    if (-not $Condition) { throw $Message }
}

function Invoke-Scenario($Name, $Target, $Filter, $ExpectedExitCode = 0)
{
    $Env:GITHUB_OUTPUT = Join-Path $artifactPath "$Name-output.txt"
    $Env:GITHUB_STEP_SUMMARY = Join-Path $artifactPath "$Name-summary.md"
    $logPath = Join-Path $artifactPath "$Name.log"

    $arguments = @(
        '-NoProfile', '-File', "$actionPath/Invoke-SolutionOrProjectTests.ps1"
        '-SolutionOrProject', $Target
        '-Filter', $Filter
        '-Verbosity', 'quiet'
        '-Configuration', 'Debug'
        '-TestProcessTimeout', '60000'
        '-EnableDiagnosticMode:$true'
    )

    # Run in a child process so the action's exit and environment changes don't affect the test harness.
    & (Join-Path $PSHOME 'pwsh') @arguments *> $logPath

    if ($LASTEXITCODE -ne $ExpectedExitCode)
    {
        Get-Content $logPath | Write-Output
        throw "$Name returned $LASTEXITCODE instead of $ExpectedExitCode."
    }
}

Push-Location $PSScriptRoot

try
{
    $Env:PATH = (Join-Path $repositoryPath 'Scripts') + [IO.Path]::PathSeparator + $Env:PATH
    $Env:GITHUB_ACTIONS = 'true'
    $Env:GITHUB_WORKSPACE = $repositoryPath
    $Env:LGHA_TEST_FAILURE = 'false'

    # The fixture name deliberately has no '.Tests.' segment; discovery must use MSBuild properties.
    Invoke-Scenario -Name passing -Target Fixture.slnx -Filter 'FullyQualifiedName!~ControlledFailure'
    $passingLog = Get-Content (Join-Path $artifactPath 'passing.log') -Raw
    Assert-True ($passingLog -like '*Passing test output is preserved.*') 'Passing test output was lost.'

    $reportPath = Join-Path $PSScriptRoot 'TestResults/Fixture_net10.0_x64.trx'
    [xml]$report = Get-Content $reportPath -Raw
    Assert-True ($report.TestRun.ResultSummary.Counters.passed -eq '3') 'Expected three passing tests in the TRX report.'
    Assert-True (Test-Path $Env:GITHUB_STEP_SUMMARY) 'The native GitHub Actions summary was not generated.'
    Assert-True (Get-ChildItem (Join-Path $PSScriptRoot 'DiagnosticLogs') -Filter '*.diag') 'MTP diagnostic logs were not generated.'

    Invoke-Scenario -Name empty-solution -Target Fixture.slnx -Filter 'FullyQualifiedName~DoesNotExist'
    Invoke-Scenario -Name empty-project -Target Fixture.csproj -Filter 'FullyQualifiedName~DoesNotExist' -ExpectedExitCode 100

    $Env:LGHA_TEST_FAILURE = 'true'
    Invoke-Scenario -Name failing -Target Fixture.csproj -Filter 'FullyQualifiedName~ControlledFailure' -ExpectedExitCode 100
    [xml]$report = Get-Content $reportPath -Raw
    Assert-True ($report.TestRun.ResultSummary.Counters.failed -eq '1') 'Expected one intentional failure in the TRX report.'
    $summary = Get-Content $Env:GITHUB_STEP_SUMMARY -Raw
    Assert-True ($summary -like '*ControlledFailure*') 'Failure details are missing from the native GitHub Actions summary.'

    Write-Output 'MTP action regression checks passed: filtering, theory discovery, output, reports, diagnostics, empty selections, and failure exit codes.'
}
finally
{
    Pop-Location
    foreach ($entry in $savedEnvironment.GetEnumerator())
    {
        [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value)
    }
}

# GitHub Actions checks LASTEXITCODE after the script returns. The final negative scenario deliberately returns 100.
exit 0
