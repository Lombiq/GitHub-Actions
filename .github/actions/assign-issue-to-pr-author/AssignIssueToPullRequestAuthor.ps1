param(
    [string] $IssueQuery,
    [string] $Assignee,
    [string] $GitHubRepository,
    [string] $PullRequestID
)

$output = gh issue list $IssueQuery --repo $GitHubRepository
$firstItem = ($output | Select-Object -First 1)

if ($firstItem) {
    gh issue add-assignee --assignee $Assignee --repo $GitHubRepository --issue $firstItem.number
} else {
    Write-Output "No issue was found with the query '$IssueQuery' in the repository '$GitHubRepository'"
}