param(
    [string] $Repository,
    [string] $SourceBranch,
    [string] $TargetBranch,
    [string] $PullRequestTitle,
    [string] $PullRequestBody = ''
)

$comparison = gh api "repos/$Repository/compare/$TargetBranch...$SourceBranch" | ConvertFrom-Json
if ($comparison.ahead_by -eq 0)
{
    Write-Output "::notice::No changes between '$SourceBranch' and '$TargetBranch', skipping pull request creation."
    exit 0
}

$existingPullRequest = gh pr list --repo $Repository --head $SourceBranch --base $TargetBranch --state open
if ($existingPullRequest)
{
    Write-Output "::notice::Pull request already exists for '$SourceBranch' -> '$TargetBranch', skipping."
    exit 0
}

$escapedTitle = $PullRequestTitle -replace '"', '\"'
$escapedBody = $PullRequestBody -replace '"', '\"'

gh pr create --repo $Repository --head $SourceBranch --base $TargetBranch --title $escapedTitle --body $escapedBody
