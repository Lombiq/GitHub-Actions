# We need to fetch the PR timeline details from the API because the context does not contain
# this granular information.

param($Repository, $PullRequestNumber)

$repoTokens = $Repository.Split("/")

$repositoryOwner = $repoTokens[0]
$repositoryName = $repoTokens[1]

Write-Output "owner=$repositoryOwner"
Write-Output "name=$repositoryName"

$query = "query(`$owner: String!, `$name: String!) {  repository(owner: `$owner name: `$name) {    pullRequest(number:$PullRequestNumber) {      timelineItems(itemTypes:ADDED_TO_MERGE_QUEUE_EVENT) {        totalCount      }    } } }"
Write-Output "query=$query"

$content = gh api graphql -F owner=$repositoryOwner -F name=$repositoryName -f query=$query | ConvertFrom-Json -ashashtable
Write-Output "content=$content"

$addedToMergeQueue = $content.data.repository.pullRequest.timelineItems.totalCount -gt 0
Write-Output "addedToMergeQueue=$addedToMergeQueue"

Set-GitHubOutput 'added-to-merge-queue' $addedToMergeQueue
