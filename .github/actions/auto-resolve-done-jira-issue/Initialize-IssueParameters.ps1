param($Repository, $PullRequestNumber, $IsDone, $IsResolve)

# We need to fetch the PR details from the API as opposed to just using the context, because the title may be changed
# (by the user or the add-jira-issue-code-to-pull-request action) after the start of the run and that wouldn't be
# present in it.
$url = "https://api.github.com/repos/$Repository/pulls/$PullRequestNumber"
$response = Invoke-WebRequest $url -Headers (Get-GitHubApiAuthorizationHeader) -Method Get
$content = $response | ConvertFrom-Json
$issueKey = Get-JiraIssueKeyFromPullRequestTitle $content.title

Set-GitHubOutput 'key' $issueKey

if ($IsDone)
{
    $transition = 'Done'
}
elseif ($IsResolve)
{
    $transition = 'Resolve'
}
else
{
    $transition = ''
}

Set-GitHubOutput 'transition' $transition

Set-GitHubOutput 'can-transition' (-not [string]::IsNullOrEmpty($issueKey) -and $transition -not '')
