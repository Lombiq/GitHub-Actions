param(
    [string] $Body,
    [string] $Assignee,
    [string] $GitHubRepository
)

$Jira_Key = if ("$Body" -match '\[(.*?)\]')
{
    $Matches[1]
}
else
{
    'No_Key_added'
}

$IssueQuery = "$Jira_Key in:title"
$Output = gh issue list --search $IssueQuery --repo $GitHubRepository
$FirstItem = ($Output | Select-Object -First 1)
$IssueNumber = $FirstItem -split '\t' | Select-Object -First 1

if ($FirstItem)
{
    gh api -X PATCH "/repos/$GitHubRepository/issues/$IssueNumber" -f "assignee=$Assignee"
}
else
{
    Write-Output "No issue was found with the query '$IssueQuery' in the repository '$GitHubRepository'"
}
