# We need to fetch the PR timeline details from the API because the context does not contain
# this granular information.

param($Repository, $PullRequestNumber)

$repoTokens = $Repository.Split('/')

$repositoryOwner = $repoTokens[0]
$repositoryName = $repoTokens[1]

Write-Output "owner=$repositoryOwner"
Write-Output "name=$repositoryName"

$contentJson = gh api graphql -F owner=$repositoryOwner -F name=$repositoryName -F prNumber=$PullRequestNumber -f query='
query($owner: String!, $name: String!, $prNumber: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $prNumber) {
      number
      title
      author {
        login
      }
      reviewDecision
      autoMergeRequest {
        enabledBy {
          login
        }
      }
    }
  }
}'

$content = $contentJson | ConvertFrom-Json -AsHashtable
Write-Output "content=$contentJson"

$reviewApproved = "$($content.data.repository.pullRequest.reviewDecision)" -eq 'APPROVED'
Write-Output "reviewApproved=$reviewApproved"

$autoMergeEnabled = -not [string]::IsNullOrWhiteSpace("$($content.data.repository.pullRequest.autoMergeRequest.enabledBy.login)")
Write-Output "autoMergeEnabled=$autoMergeEnabled"

$addedToMergeQueue = $reviewApproved -and $autoMergeEnabled
Write-Output "addedToMergeQueue=$addedToMergeQueue"

Set-GitHubOutput 'added-to-merge-queue' $addedToMergeQueue
