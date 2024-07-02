param (
    [string] $Configuration,
    [string] $SolutionOrProject,
    [string] $Verbosity,
    [string] $EnableCodeAnalysis,
    [string] $Version,
    [string] $Switches,
    [string] $ExpectedCodeAnalysisErrors,
    [boolean] $CreateBinaryLog,
    [boolean] $WarningsAsErrors)

function ConvertTo-Array([string] $RawInput)
{
    $RawInput.Replace("`r", '').Split("`n") | ForEach-Object { $PSItem.Trim() } | Where-Object { $PSItem }
}

Write-Output "Version number for the .NET build products: $Version"

# Notes on build switches that aren't self-explanatory:
# - -p:Retries and -p:RetryDelayMilliseconds are used to retry builds when they fail due to random locks.
# - --warnAsMessage:MSB3026 is also to prevent random locks along the lines of "warning MSB3026: Could not copy dlls
#   errors." from breaking the build (since we treat warnings as errors).

$buildSwitches = ConvertTo-Array @"
    --configuration:$Configuration
    --nologo
    --verbosity:$Verbosity
    $($WarningsAsErrors ? '--warnaserror' : '')
    --warnAsMessage:MSB3026
    --consoleLoggerParameters:NoSummary
    -p:TreatWarningsAsErrors=$WarningsAsErrors
    -p:RunAnalyzersDuringBuild=$EnableCodeAnalysis
    -p:Retries=4
    -p:RetryDelayMilliseconds=1000
    -p:Version=$Version
    $($CreateBinaryLog ? '-binaryLogger:build.binlog' : '')
    $Switches
"@

[array] $expectedErrorCodes = ConvertTo-Array $ExpectedCodeAnalysisErrors | ForEach-Object { $PSItem.Split(':')[0] } | Sort-Object
$noErrorsExpected = $expectedErrorCodes.Count -eq 0

if (Test-Path src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj)
{
    Write-Output '::group::Gulp Extensions found. It needs to be explicitly built before the solution.'

    $startTime = [DateTime]::Now
    dotnet build src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj @buildSwitches
    $endTime = [DateTime]::Now

    Write-Output ('Gulp Extensions build took {0:0.###} seconds.' -f ($endTime - $startTime).TotalSeconds)
    Write-Output '::endgroup::'
}

# This prepares the solution or project with the Lombiq.Analyzers files. The output and exit code are discarded because
# they will be in error if there is a project without the LombiqNetAnalyzers target. Then there is nothing to do, and
# the target will still run on the projects that have it.
dotnet msbuild '-target:Restore;LombiqNetAnalyzers' $SolutionOrProject | Out-Null || bash -c 'true'

Write-Output "Building solution or project with ``dotnet build $SolutionOrProject $($buildSwitches -join ' ')``."

$errorLines = New-Object 'System.Collections.Generic.List[string]'
$errorCodes = New-Object 'System.Collections.Generic.List[string]'

$errorFormat = '^(.*)\((\d+),(\d+)\): error (.*)'
dotnet build $SolutionOrProject @buildSwitches 2>&1 | ForEach-Object {
    if ($PSItem -notmatch $errorFormat) { return $PSItem }

    ($null, $file, $line, $column, $message) = [regex]::Match($PSItem, $errorFormat, 'Compiled').Groups.Value

    $errorLines.Add($PSItem)
    if ($message.Contains(':')) { $errorCodes.Add($message.Split(':')[0].Trim()) }
    if ($noErrorsExpected) { Write-Output "::error file=$file,line=$line,col=$column::$message" }
}

if ($noErrorsExpected -and -not $?)
{
    exit 1
}

Stop-DotNetBuildServers

if ($expectedErrorCodes)
{
    $errorCodes = $errorCodes | Sort-Object
    $fail = 0
    $report = New-Object 'System.Text.StringBuilder' "`n"

    if ($null -eq $errorCodes -or -not $errorCodes.Count)
    {
        $expectedCount = $expectedErrorCodes.Count
        $expectedCodesJoined = $expectedErrorCodes -join ', '

        Write-Output "::error::Expected $expectedCount error codes ($expectedCodesJoined), but none were displayed."
        exit 1
    }

    $length = [System.Math]::Max($errorCodes.Count, $expectedErrorCodes.Count)
    foreach ($index in 0..($length - 1))
    {
        $actual = $errorCodes[$index]
        $expected = $expectedErrorCodes[$index]

        if ($actual -eq $expected)
        {
            $report.AppendLine("#$index OK ($actual)") | Out-Null
        }
        else
        {
            $report.AppendLine("#$index FAIL (expected: $expected; actual: $actual)") | Out-Null
            $fail++
        }
    }

    if ($fail -gt 0)
    {
        Write-Warning $report.ToString() # We use warning so it doesn't stop prematurely.
        Write-Output ('::error::Verification Mismatch ' + ($errorLines -join ' '))
        exit 1
    }

    Write-Output 'Verification complete, the solution or project only has the expected errors!'
    exit 0
}
