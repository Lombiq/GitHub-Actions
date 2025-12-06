param(
    [string] $Repository,
    [int] $PullRequestNumber,
    [string] $EventName,
    [string] $TargetRef,
    [string] $LastReviewApproved
)

$message = ''

if ($EventName -eq 'pull_request_review' -and $LastReviewApproved -eq 'True')
{
    $message = "✅ This PR has been approved! GitHub Actions references have been automatically updated to point to ``$TargetRef`` (the target branch)."
}
elseif ($EventName -eq 'pull_request')
{
    $message = "🔄 GitHub Actions references have been automatically updated to point to ``$TargetRef`` (this PR's branch) to ensure the latest changes are tested."
    
    if ($LastReviewApproved -eq 'True')
    {
        $message += "`n`n⚠️ Note: This PR was previously approved, but new commits have been pushed. The references have been updated to the PR branch to test the latest changes."
    }
}
else
{
    $message = "🔄 GitHub Actions references have been automatically updated to point to ``$TargetRef``."
}

$message += "`n`n_To disable automatic reference management, add the ``dont-auto-manage-gha-refs`` label to this PR._"

# Create comment using GitHub CLI.
gh api "repos/$Repository/issues/$PullRequestNumber/comments" `
    --method POST `
    --field "body=$message" | Out-Null

Write-Output "Comment posted to PR #$PullRequestNumber"
