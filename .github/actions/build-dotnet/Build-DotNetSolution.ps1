param (
    [string] $Solution,
    [string] $Verbosity,
    [string] $EnableCodeAnalysis,
    [string] $Version,
    [string] $Switches,
    [string] $ExpectedCodeAnalysisErrors)

function ConvertTo-Array([string] $rawInput)
{
    $rawInput.Replace("`r", "").Split("`n") |
        % { $_.Trim() } |
        ? { -not [string]::IsNullOrEmpty($_) }
}

Write-Output ".NET version number: $Version"

# Notes on build switches that aren't self-explanatory:
# - -p:Retries and -p:RetryDelayMilliseconds are to retry builds if it fails the first time due to random locks.
# - --warnAsMessage:MSB3026 is also to prevent random locks along the lines of "warning MSB3026: Could not copy dlls
#   errors." from breaking the build (since we treat warnings as errors).

$buildSwitches = ConvertTo-Array @"
    --configuration:Release
    --nologo
    --verbosity:$Verbosity
    --warnaserror
    --warnAsMessage:MSB3026
    --consoleLoggerParameters:NoSummary
    -p:TreatWarningsAsErrors=true
    -p:RunAnalyzersDuringBuild=$EnableCodeAnalysis
    -p:Retries=4
    -p:RetryDelayMilliseconds=1000
    -p:Version=$Version
    $Switches
"@

[array] $expectedErrorCodes = ConvertTo-Array $ExpectedCodeAnalysisErrors | % { $_.Split(':')[0] } | Sort-Object
$noErrors = $expectedErrorCodes.Count -eq 0

if (Test-Path src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj)
{
    Write-Output "::group::Gulp Extensions found. It needs to be explicitly built before the solution."

    $startTime = [DateTime]::Now
    dotnet build src/Utilities/Lombiq.Gulp.Extensions/Lombiq.Gulp.Extensions.csproj @buildSwitches
    $endTime = [DateTime]::Now

    Write-Output ("Gulp Extensions build took {0:0.###} seconds." -f ($endTime - $startTime).TotalSeconds)
    Write-Output "::endgroup::"
}

Write-Output "Building solution with ``dotnet build $Solution $($buildSwitches -join " ")``."

$errorFormat = '^(.*)\((\d+),(\d+)\): error (.*)'
$errorLines = New-Object "System.Collections.Generic.List[string]"
$errorCodes = New-Object "System.Collections.Generic.List[string]"

# Since dotnet build will allways emit an error message when it fails, we don't need to care about its exit code. To
# dismiss it, this line calls Out-Null when dotnet build has a non-zero exit code. This has no effect.
foreach ($output in (dotnet build $Solution @buildSwitches 2>&1))
{
    bash -c "exit 0" # This command clears the output, so the loop doesn't halt early on in Windows.
    Write-Output "ASD 0: $? $output"

    if ($output -notmatch $errorFormat) { return $output }

    ($null, $file, $line, $column, $message) = [regex]::Match($output, $errorFormat).Groups.Value

    $errorLines.Add($output)
    if ($message.Contains(":")) { $errorCodes.Add($message.Split(":")[0].Trim()) }
    if ($noErrors) { Write-Output "::error file=$file,line=$line,col=$column::$message" }
}

Write-Output "ASD 1: $expectedErrorCodes"
if ($expectedErrorCodes)
{
    $errorCodes = $errorCodes | Sort-Object
    $fail = 0
    $report = New-Object "System.Text.StringBuilder" "`n"

    $length = [System.Math]::Max($errorCodes.Count, $expectedErrorCodes.Count)
    Write-Output "ASD 2: $length"
    foreach ($index in 0..($length - 1))
    {
        $actual = $errorCodes[$index]
        $expected = $expectedErrorCodes[$index]
        Write-Output "ASD 3: '$actual' - '$expected' : $($actual -eq $expected)"

        if ($actual -eq $expected)
        {
            $report.AppendLine("#$index OK ($actual)") | Out-Null
        } else
        {
            $report.AppendLine("#$index FAIL (expected: $expected; actual: $actual)") | Out-Null
            $fail++
        }

        Write-Output ("ASD4: $fail`n" + $report.ToString())
    }

    Write-Output "ASD 5: $fail"
    if ($fail -gt 0) {
        Write-Warning $report.ToString() # We use warning so it doesn't stop prematurely.
        Write-Output ("::error::Verification Mismatch " + ($errorLines -join " "))
        exit 1
    }

    Write-Output "ASD 6: EXIT"
    Write-Output "Verification complete, the solution only has the expected errors!"
    exit 0
}

