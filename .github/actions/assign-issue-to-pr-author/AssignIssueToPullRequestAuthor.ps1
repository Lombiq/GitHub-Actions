param(
    [string] $Body,
    [string] $Assignee,
    [string] $GitHubRepository,
    [string] $PullRequestID
)

$Jira_Key = if ("$Body" -match '\[(.*?)\]') { $Matches[1] } else { "No_Key_added" }
$IssueQuery = "$Jira_Key in:title"
$output = gh issue list --search $IssueQuery --repo $GitHubRepository
Write-Output $output
$firstItem = ($output | Select-Object -First 1)
Write-Output $firstItem

if ($firstItem) {
    gh api -X PATCH "/repos/$GitHubRepository/issues/$firstItem.number" -f "assignees=$Assignee"
} else {
    Write-Output "No issue was found with the query '$IssueQuery' in the repository '$GitHubRepository'"
}