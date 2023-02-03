param(
    [string] $IssueQuery,
    [string] $Assignee,
    [string] $GitHubRepository,
    [string] $PullRequestID
)

$output = gh issue list --search $IssueQuery --repo $GitHubRepository
$firstItem = ($output | Select-Object -First 1).number

if ($firstItem) {
    gh api -X PATCH "/repos/$GitHubRepository/issues/$firstItem.number" -f "assignees=$Assignee"
} else {
    Write-Output "No issue was found with the query '$IssueQuery' in the repository '$GitHubRepository'"
}