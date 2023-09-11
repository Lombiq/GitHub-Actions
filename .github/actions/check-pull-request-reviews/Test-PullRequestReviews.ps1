# We need to fetch the PR details from the API as opposed to just using the context because a review added after the
# start of the run wouldn't be present in it.

param($Repository, $PullRequestNumber)

# See https://cli.github.com/manual/gh_pr_view
$content = gh api "repos/$Repository/pulls/$PullRequestNumber/reviews" | ConvertFrom-Json
$lastReviewApproved = ($content | Select-Object -Last 1).state -eq 'APPROVED'

Set-GitHubOutput 'last-review-approved' $lastReviewApproved
