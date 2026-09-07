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

$endpoint = "repos/$Repository/issues/$number/labels"

if ($Operation -ceq 'add')
{
    @{ labels = $labelsToUpdate } | ConvertTo-Json -Compress | gh api --method POST $endpoint --input - --silent
    if ($LASTEXITCODE -ne 0) { throw 'Failed to add labels.' }
    return
}

# Removing an absent label should succeed, including on repeated workflow runs.
$existingLabels = @(gh api --paginate $endpoint --jq '.[].name')
if ($LASTEXITCODE -ne 0) { throw 'Failed to read labels.' }

foreach ($labelToUpdate in ($labelsToUpdate | Select-Object -Unique))
{
    if ($existingLabels -contains $labelToUpdate)
    {
        $encodedLabel = [Uri]::EscapeDataString($labelToUpdate)
        gh api --method DELETE "$endpoint/$encodedLabel" --silent
        if ($LASTEXITCODE -ne 0) { throw "Failed to remove label '$labelToUpdate'." }
    }
}
