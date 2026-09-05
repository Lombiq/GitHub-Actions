$ErrorActionPreference = 'Stop'
$eventPath = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
$global:labelTestCalls = [Collections.Generic.List[object]]::new()
$global:labelTestExistingLabels = @()
$global:labelTestFailureMethod = ''

# Mock the CLI so these tests never change a real issue or pull request.
function gh
{
    $body = @($input) -join ''
    $global:labelTestCalls.Add(@{ Arguments = @($args); Body = $body })
    $global:LASTEXITCODE = 0
    if ($global:labelTestFailureMethod -and $args -contains $global:labelTestFailureMethod)
    {
        $global:LASTEXITCODE = 1
    }
    if ($args -contains '--paginate') { $global:labelTestExistingLabels }
}

function Assert-True($Condition, $Message)
{
    if (!$Condition) { throw $Message }
}

function Invoke-TestUpdate($EventJson, $Operation, $Label = '', $Labels = '')
{
    $global:labelTestCalls.Clear()
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
    Invoke-TestUpdate '{"pull_request":{"number":42}}' add 'a, single label'
    Assert-True ($global:labelTestCalls.Count -eq 1) 'Adding a label must make one request.'
    Assert-True ($global:labelTestCalls[0].Arguments -contains 'repos/owner/repo/issues/42/labels') 'Wrong pull request endpoint.'
    $body = $global:labelTestCalls[0].Body | ConvertFrom-Json
    Assert-True ($body.labels.Count -eq 1 -and $body.labels[0] -ceq 'a, single label') 'Single label was split.'

    Invoke-TestUpdate '{"issue":{"number":7}}' add ignored ' first, ,second '
    $body = $global:labelTestCalls[0].Body | ConvertFrom-Json
    Assert-True (($body.labels -join '|') -ceq 'first|second') 'Plural labels must take precedence and be trimmed.'
    Assert-True ($global:labelTestCalls[0].Arguments -contains 'repos/owner/repo/issues/7/labels') 'Wrong issue endpoint.'

    $specialLabel = 'quote" slash/ # & $(never-execute)'
    Invoke-TestUpdate '{"issue":{"number":7}}' add $specialLabel
    Assert-True (($global:labelTestCalls[0].Body | ConvertFrom-Json).labels[0] -ceq $specialLabel) 'Label must survive JSON encoding.'

    $global:labelTestExistingLabels = @($specialLabel)
    Invoke-TestUpdate '{"issue":{"number":7}}' remove $specialLabel
    $expectedEndpoint = 'repos/owner/repo/issues/7/labels/' + [Uri]::EscapeDataString($specialLabel)
    Assert-True ($global:labelTestCalls.Count -eq 2 -and $global:labelTestCalls[1].Arguments -contains $expectedEndpoint) 'Removal must URL-encode labels.'

    $global:labelTestExistingLabels = @('present')
    Invoke-TestUpdate '{"issue":{"number":7}}' remove '' 'present, missing, present'
    Assert-True ($global:labelTestCalls.Count -eq 2) 'Only existing, unique labels should be removed.'

    $global:labelTestExistingLabels = @()
    Invoke-TestUpdate '{"issue":{"number":7}}' remove present
    Assert-True ($global:labelTestCalls.Count -eq 1) 'Removing an absent label must succeed without a DELETE.'

    Invoke-TestUpdate '{"ref":"refs/heads/dev"}' add example
    Assert-True ($global:labelTestCalls.Count -eq 0) 'Push events must not make label requests.'
    Invoke-TestUpdate '{"issue":{"number":7}}' add
    Assert-True ($global:labelTestCalls.Count -eq 0) 'Empty labels must not make requests.'

    foreach ($method in @('POST', '--paginate', 'DELETE'))
    {
        $global:labelTestFailureMethod = $method
        $global:labelTestExistingLabels = @('present')
        $failed = $false
        try { Invoke-TestUpdate '{"issue":{"number":7}}' ($method -eq 'POST' ? 'add' : 'remove') present }
        catch { $failed = $true }
        Assert-True $failed "A failed $method request must fail the action."
    }

    $global:labelTestFailureMethod = ''
    $failed = $false
    try { Invoke-TestUpdate '{"issue":{"number":7}}' invalid example }
    catch { $failed = $true }
    Assert-True $failed 'Invalid operations must fail.'

    Write-Output 'All label update tests passed.'
}
finally
{
    Remove-Item -LiteralPath $eventPath
}
