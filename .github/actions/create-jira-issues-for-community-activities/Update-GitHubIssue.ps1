param(
    [Parameter(Mandatory = $true)]
    [string] $IssueNumber,
    [Parameter(Mandatory = $true)]
    [string] $IssueTitle,
    [string] $IssueBody,
    [Parameter(Mandatory = $true)]
    [string] $JiraIssueKey,
    [Parameter(Mandatory = $true)]
    [string] $JiraIssueUrl,
    [Parameter(Mandatory = $true)]
    [string] $Repository
)

$issueNumberInt = 0

if (-not [int]::TryParse($IssueNumber, [ref]$issueNumberInt))
{
    throw "The issue number '$IssueNumber' is not a valid integer."
}

$title = "$IssueTitle ($JiraIssueKey)"

$jiraIssueLink = "[Jira issue]($JiraIssueUrl)"

$body = [string]::IsNullOrWhiteSpace($IssueBody) ? $jiraIssueLink : "$IssueBody`n`n$jiraIssueLink"

$requestBody = @{
    title = $title
    body = $body
} | ConvertTo-Json -Compress

$ghApiParameters = @(
    'api'
    '--method'
    'PATCH'
    '--header'
    'Accept: application/vnd.github+json'
    "/repos/$Repository/issues/$issueNumberInt"
    '--input'
    '-'
)

$requestBody | & gh @ghApiParameters
