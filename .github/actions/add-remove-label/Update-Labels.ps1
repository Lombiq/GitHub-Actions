$ErrorActionPreference = 'Stop'

$event = Get-Content -LiteralPath $Env:GITHUB_EVENT_PATH -Raw | ConvertFrom-Json
$number = $event.pull_request.number ?? $event.issue.number

# Push and other events without an issue or pull request have no labels to update.
if (!$number)
{
    return
}

if ($Env:LABEL_OPERATION -cnotin @('add', 'remove'))
{
    throw 'The label operation must be add or remove.'
}

# The plural input takes precedence, while a single label can itself contain a comma.
$labels = @(
    if ($Env:LABELS)
    {
        $Env:LABELS.Split(',').Trim() | Where-Object { $_ }
    }
    elseif ($Env:LABEL)
    {
        $Env:LABEL
    }
)

if ($labels.Count -eq 0)
{
    return
}

$endpoint = "repos/$Env:GITHUB_REPOSITORY/issues/$number/labels"

if ($Env:LABEL_OPERATION -ceq 'add')
{
    @{ labels = $labels } | ConvertTo-Json -Compress | gh api --method POST $endpoint --input - --silent
    if ($LASTEXITCODE -ne 0) { throw 'Failed to add labels.' }
    return
}

# Removing an absent label should succeed, including on repeated workflow runs.
$existingLabels = @(gh api --paginate $endpoint --jq '.[].name')
if ($LASTEXITCODE -ne 0) { throw 'Failed to read labels.' }

foreach ($label in ($labels | Select-Object -Unique))
{
    if ($existingLabels -ccontains $label)
    {
        $encodedLabel = [Uri]::EscapeDataString($label)
        gh api --method DELETE "$endpoint/$encodedLabel" --silent
        if ($LASTEXITCODE -ne 0) { throw "Failed to remove label '$label'." }
    }
}
