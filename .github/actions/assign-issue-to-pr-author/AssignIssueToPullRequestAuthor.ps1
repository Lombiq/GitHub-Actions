param(
    [string] $Body,
    [string] $Assignee,
    [string] $GitHubRepository
)

$jira_Key = if ("$Body" -match '\[(.*?)\]')
{
    $Matches[1]
}
else
{
    'No_Key_added'
}

$issueQuery = "$jira_Key in:title"
$output = gh issue list --search $issueQuery --repo $GitHubRepository
$firstItem = ($output | Select-Object -First 1)
$issueNumber = $firstItem -split '\t' | Select-Object -First 1

if ($firstItem)
{
    gh issue edit [int]$issueNumber --add-assignee $Assignee
}
else
{
    Write-Output "No issue was found with the query '$issueQuery' in the repository '$GitHubRepository'"
}
