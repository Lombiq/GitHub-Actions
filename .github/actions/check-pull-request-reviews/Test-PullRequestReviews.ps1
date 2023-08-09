# We need to fetch the PR details from the API as opposed to just using the context because a review added after the
# start of the run wouldn't be present in it.

param($Repository, $PullRequestNumber)

# See https://cli.github.com/manual/gh_pr_view
$content = gh api "repos/$Repository/pulls/$PullRequestNumber/reviews" | ConvertFrom-Json

$approvedCount = $content.Where({ $PSItem.state -eq 'APPROVED' }).Count
$requestChangesCount = $content.Where({ $PSItem.state -eq 'CHANGES_REQUESTED' }).Count
$commentCount = $content.Where({ $PSItem.state -eq 'COMMENTED' }).Count
$lastReviewApproved = ($content | Select-Object -Last 1).state -eq 'APPROVED'

Set-GitHubOutput 'approved-count' $approvedCount
Set-GitHubOutput 'request-changes-count' $requestChangesCount
Set-GitHubOutput 'comment-count' $commentCount
Set-GitHubOutput 'last-review-approved' $lastReviewApproved
