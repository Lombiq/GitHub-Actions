param(
    [Parameter(Mandatory)]
    [string] $EventPath,
    [Parameter(Mandatory)]
    [string] $Repository,
    [string] $Labels = '',
    [Parameter(Mandatory)]
    [string] $Operation
)

$errorActionPreference = 'Stop'

$githubEvent = Get-Content -LiteralPath $EventPath -Raw | ConvertFrom-Json
$number = $githubEvent.pull_request.number ?? $githubEvent.issue.number

# Push and other events without an issue or pull request have no labels to update.
if (-not $number)
{
    return
}

if ($Operation -cnotin @('add', 'remove'))
{
    throw 'The label operation must be add or remove.'
}

$labelsToUpdate = @(
    if ($Labels)
    {
        $Labels.Split(',').Trim() | Where-Object { $PSItem }
    }
)

if ($labelsToUpdate.Count -eq 0)
{
    return
}

$command = $githubEvent.pull_request ? 'pr' : 'issue'

if ($Operation -ceq 'remove')
{
    # Removing an absent label should succeed, including on repeated workflow runs.
    $existingLabels = @(gh $command view $number --repo $Repository --json labels --jq '.labels[].name')
    if ($LASTEXITCODE -ne 0) { throw 'Failed to read labels.' }

    $labelsToUpdate = @($existingLabels | Where-Object { $labelsToUpdate -contains $PSItem })
    if ($labelsToUpdate.Count -eq 0) { return }
}

# gh parses label flags as CSV so labels should be escaped.
$labelNames = (
    $labelsToUpdate |
    Select-Object -Unique |
    ForEach-Object { @{ Value = $PSItem } } |
    ConvertTo-Csv -UseQuotes Always -NoHeader
) -join ','

$labelFlag = "--$Operation-label"
# issue edit also supports PRs and only queries the edited fields. pr edit unconditionally fetches team reviewers,
# requiring read:org even for label-only changes made with an otherwise sufficient repo-scoped token.
gh issue edit $number --repo $Repository $labelFlag $labelNames
if ($LASTEXITCODE -ne 0) { throw "Failed to $Operation labels." }
