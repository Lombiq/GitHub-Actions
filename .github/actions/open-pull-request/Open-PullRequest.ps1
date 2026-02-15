param(
	[string] $Repository,
	[string] $SourceBranch,
	[string] $TargetBranch,
	[string] $PullRequestTitle
)

$comparison = gh api "repos/$Repository/compare/$TargetBranch...$SourceBranch" | ConvertFrom-Json
if ($comparison.ahead_by -eq 0)
{
	Write-Output "::notice::No changes between '$SourceBranch' and '$TargetBranch', skipping pull request creation."
	exit 0
}

$existingPullRequest = gh pr list --repo $Repository --head $SourceBranch --base $TargetBranch --state all --json number --template '{{range .}}{{.number}}{{end}}'
if ($existingPullRequest)
{
	Write-Output "::notice::Pull request already exists for '$SourceBranch' -> '$TargetBranch', skipping."
	exit 0
}

$escapedTitle = $PullRequestTitle -replace '"', '\"'

gh pr create --repo $Repository --head $SourceBranch --base $TargetBranch --title $escapedTitle --body ''
