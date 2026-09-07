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
    $testState.Calls.Add(@{ Arguments = @($args) })
    $global:LASTEXITCODE = 0
    if ($testState.FailureMethod -and $args -contains $testState.FailureMethod)
    {
        $global:LASTEXITCODE = 1
    }
    if ($args -contains 'view') { $testState.ExistingLabels }
}

function Assert-True($Condition, $Message)
{
    if (-not $Condition) { throw $Message }
}

function Invoke-TestUpdate($EventJson, $Operation, $Label = '', $Labels = '')
{
    $testState.Calls.Clear()
    Set-Content -LiteralPath $eventPath -Value $EventJson
    $parameters = @{
        EventPath = $eventPath
        Repository = 'owner/repo'
        Operation = $Operation
        Label = $Label
        Labels = $Labels
    }
    & "$PSScriptRoot/Update-Labels.ps1" @parameters
}

try
{
    Invoke-TestUpdate -EventJson '{"pull_request":{"number":42}}' -Operation add -Label 'a, single label'
    Assert-True ($testState.Calls.Count -eq 1) 'Adding a label must make one edit call.'
    $arguments = $testState.Calls[0].Arguments
    Assert-True (($arguments[0..4] -join '|') -ceq 'pr|edit|42|--repo|owner/repo') 'Wrong pull request edit command.'
    Assert-True ($arguments[5] -ceq '--add-label' -and $arguments[6] -ceq '"a, single label"') 'Single label must be CSV quoted.'

    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation add -Label ignored -Labels ' first, ,second '
    $arguments = $testState.Calls[0].Arguments
    Assert-True (($arguments[0..4] -join '|') -ceq 'issue|edit|7|--repo|owner/repo') 'Wrong issue edit command.'
    Assert-True ($arguments[6] -ceq '"first","second"') 'Plural labels must take precedence and be trimmed.'

    $specialLabel = 'quote" slash/ # & $(never-execute)'
    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation add -Label $specialLabel
    $expectedLabel = '"quote"" slash/ # & $(never-execute)"'
    Assert-True ($testState.Calls[0].Arguments[6] -ceq $expectedLabel) 'Quotes must be escaped as CSV data.'

    $testState.ExistingLabels = @($specialLabel)
    Invoke-TestUpdate -EventJson '{"pull_request":{"number":42}}' -Operation remove -Label $specialLabel
    Assert-True (($testState.Calls[0].Arguments[0..2] -join '|') -ceq 'pr|view|42') 'PR labels must be read with pr view.'
    $arguments = $testState.Calls[1].Arguments
    Assert-True ($arguments[0] -ceq 'pr' -and $arguments[5] -ceq '--remove-label') 'Wrong pull request removal command.'
    Assert-True ($arguments[6] -ceq $expectedLabel) 'Removal must preserve special characters.'

    $testState.ExistingLabels = @('present')
    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation remove -Labels 'present, missing, present'
    Assert-True ($testState.Calls.Count -eq 2) 'Removal should make one view and one edit call.'
    Assert-True ($testState.Calls[1].Arguments[6] -ceq '"present"') 'Only existing, unique labels should be removed.'

    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation remove -Label PRESENT
    Assert-True ($testState.Calls[1].Arguments[6] -ceq '"present"') 'Lookup must preserve the existing label casing.'

    $testState.ExistingLabels = @()
    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation remove -Label present
    Assert-True ($testState.Calls.Count -eq 1) 'Removing an absent label must succeed without an edit.'

    Invoke-TestUpdate -EventJson '{"ref":"refs/heads/dev"}' -Operation add -Label example
    Assert-True ($testState.Calls.Count -eq 0) 'Push events must not make label requests.'
    Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation add
    Assert-True ($testState.Calls.Count -eq 0) 'Empty labels must not make requests.'

    foreach ($method in @('--add-label', 'view', '--remove-label'))
    {
        $testState.FailureMethod = $method
        $testState.ExistingLabels = @('present')
        $failed = $false
        try
        {
            $operation = $method -eq '--add-label' ? 'add' : 'remove'
            Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation $operation -Label present
        }
        catch { $failed = $true }
        Assert-True $failed "A failed $method command must fail the action."
    }

    $failed = $false
    $testState.FailureMethod = ''
    try { Invoke-TestUpdate -EventJson '{"issue":{"number":7}}' -Operation invalid -Label example }
    catch { $failed = $true }
    Assert-True $failed 'Invalid operations must fail.'

    # The Actions PowerShell shell propagates LASTEXITCODE, including our intentionally mocked CLI failures.
    $global:LASTEXITCODE = 0
    Write-Output 'All label update tests passed.'
}
finally
{
    Remove-Item -LiteralPath $eventPath
}
