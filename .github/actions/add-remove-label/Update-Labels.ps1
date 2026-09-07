param(
    [Parameter(Mandatory)]
    [string] $EventPath,
    [Parameter(Mandatory)]
    [string] $Repository,
    [Parameter(Mandatory)]
    [string] $Operation,
    [string] $Label = '',
    [string] $Labels = ''
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

# The plural input takes precedence, while a single label can itself contain a comma.
$labelsToUpdate = @(
    if ($Labels)
    {
        $Labels.Split(',').Trim() | Where-Object { $PSItem }
    }
    elseif ($Label)
    {
        $Label
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

# gh parses label flags as CSV. Quote each field to preserve commas and double quotes within a single label.
$labelNames = ($labelsToUpdate | Select-Object -Unique | ForEach-Object { '"' + $PSItem.Replace('"', '""') + '"' }) -join ','
$labelFlag = "--$Operation-label"
gh $command edit $number --repo $Repository $labelFlag $labelNames
if ($LASTEXITCODE -ne 0) { throw "Failed to $Operation labels." }
