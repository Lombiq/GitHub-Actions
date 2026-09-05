$errorActionPreference = 'Stop'
$eventPath = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
$testState = @{
    Calls = [Collections.Generic.List[object]]::new()
    ExistingLabels = @()
    FailureMethod = ''
}

# Mock the CLI so these tests never change a real issue or pull request.
function gh
{
    $body = @($input) -join ''
    $testState.Calls.Add(@{ Arguments = @($args); Body = $body })
    $global:LASTEXITCODE = 0
    if ($testState.FailureMethod -and $args -contains $testState.FailureMethod)
    {
        $global:LASTEXITCODE = 1
    }
    if ($args -contains '--paginate') { $testState.ExistingLabels }
}

function Assert-True($Condition, $Message)
{
    if (-not $Condition) { throw $Message }
}

function Invoke-TestUpdate($EventJson, $Operation, $Label = '', $Labels = '')
{
    $testState.Calls.Clear()
    Set-Content -LiteralPath $eventPath -Value $EventJson
    $Env:GITHUB_EVENT_PATH = $eventPath
    $Env:GITHUB_REPOSITORY = 'owner/repo'
    $Env:LABEL_OPERATION = $Operation
    $Env:LABEL = $Label
    $Env:LABELS = $Labels
    & "$PSScriptRoot/Update-Labels.ps1"
}

try
{
    Invoke-TestUpdate -EventJson '{"pull_request":{"number":42}}' -Operation add -Label 'a, single label'
    Assert-True ($testState.Calls.Count -eq 1) 'Adding a label must make one request.'
    Assert-True ($testState.Calls[0].Arguments -contains 'repos/owner/repo/issues/42/labels') 'Wrong pull request endpoint.'
    $body = $testState.Calls[0].Body | ConvertFrom-Json
    Assert-True ($body.labels.Count -eq 1 -and $body.labels[0] -ceq 'a, single label') 'Single label was split.'

    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation add -Label ignored -Labels ' first, ,second '
    $body = $testState.Calls[0].Body | ConvertFrom-Json
    Assert-True (($body.labels -join '|') -ceq 'first|second') 'Plural labels must take precedence and be trimmed.'
    Assert-True ($testState.Calls[0].Arguments -contains 'repos/owner/repo/issues/7/labels') 'Wrong issue endpoint.'

    $specialLabel = 'quote" slash/ # & $(never-execute)'
    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation add -Label $specialLabel
    Assert-True (($testState.Calls[0].Body | ConvertFrom-Json).labels[0] -ceq $specialLabel) 'Label must survive JSON encoding.'

    $testState.ExistingLabels = @($specialLabel)
    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation remove -Label $specialLabel
    $expectedEndpoint = 'repos/owner/repo/issues/7/labels/' + [Uri]::EscapeDataString($specialLabel)
    Assert-True ($testState.Calls.Count -eq 2 -and $testState.Calls[1].Arguments -contains $expectedEndpoint) 'Removal must URL-encode labels.'

    $testState.ExistingLabels = @('present')
    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation remove -Labels 'present, missing, present'
    Assert-True ($testState.Calls.Count -eq 2) 'Only existing, unique labels should be removed.'

    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation remove -Label PRESENT
    Assert-True ($testState.Calls.Count -eq 2) 'Label lookup must be case-insensitive, like GitHub label names.'

    $testState.ExistingLabels = @()
    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation remove -Label present
    Assert-True ($testState.Calls.Count -eq 1) 'Removing an absent label must succeed without a DELETE.'

    Invoke-TestUpdate -EventJson '{"ref":"refs/heads/dev"}' -Operation add -Label example
    Assert-True ($testState.Calls.Count -eq 0) 'Push events must not make label requests.'
    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation add
    Assert-True ($testState.Calls.Count -eq 0) 'Empty labels must not make requests.'

    foreach ($method in @('POST', '--paginate', 'DELETE'))
    {
        $testState.FailureMethod = $method
        $testState.ExistingLabels = @('present')
        $failed = $false
        try
        {
            $operation = $method -eq 'POST' ? 'add' : 'remove'
            Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation $operation -Label present
        }
        catch { $failed = $true }
        Assert-True $failed "A failed $method request must fail the action."
    }

    $failed = $false
    $testState.FailureMethod = ''
    try { Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation invalid -Label example }
    catch { $failed = $true }
    Assert-True $failed 'Invalid operations must fail.'

    # The Actions PowerShell shell propagates LASTEXITCODE, including our intentionally mocked API failures.
    $global:LASTEXITCODE = 0
    Write-Output 'All label update tests passed.'
}
finally
{
    Remove-Item -LiteralPath $eventPath
}
