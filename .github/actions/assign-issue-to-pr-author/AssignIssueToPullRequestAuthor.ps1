param(
    [string] $IssueQuery,
    [string] $Assignee,
    [string] $GitHubRepository,
    [string] $PullRequestID,
)

$output = gh issue search $IssueQuery --repo $GitHubRepository
$firstItem = ($output | Select-Object -First 1)
gh issue add-assignee --assignee $Assignee --repo $GitHubRepository --issue $firstItem.number