param($Repository, $PullRequestNumber, $IsDone, $IsResolve)

# We need to fetch the PR details using the CLI (see https://cli.github.com/manual/gh_pr_view) as opposed to just using
# the context, because the title may have changed (by the user or the add-jira-issue-code-to-pull-request action) after
# the start of the run and that wouldn't be present in it.
$title = gh pr view $PullRequestNumber --repo $Repository --json title --template '{{.title}}'
$issueKey = Get-JiraIssueKeyFromPullRequestTitle $title

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
Set-GitHubOutput 'can-transition' (-not [string]::IsNullOrEmpty($issueKey) -and $transition -ne '')
