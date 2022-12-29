# We need to fetch the PR details from the API as opposed to just using the context because a label added after the
# start of the run wouldn't be present in it.

param($Repository, $PullRequestNumber, $Label1, $Label2)

# See https://cli.github.com/manual/gh_pr_view
$content = gh pr view $PullRequestNumber --repo $Repository --json labels | ConvertFrom-Json

$labelFound = $content.labels.Where({ $PSItem.name -eq $Label1 -or $PSItem.name -eq $Label2 }, 'First').Count -gt 0

Set-GitHubOutput 'contains-label' $labelFound
