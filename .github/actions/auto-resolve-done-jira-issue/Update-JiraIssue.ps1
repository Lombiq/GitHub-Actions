param($Repository, $PullRequestNumber, $IsDone, $IsResolve)

# We need to fetch the PR details using the CLI (see https://cli.github.com/manual/gh_pr_view) as opposed to just using
# the context, because the title may have changed (by the user or the add-jira-issue-code-to-pull-request action) after
# the start of the run and that wouldn't be present in it.
$title = gh pr view $PullRequestNumber --repo $Repository --json title --template '{{.title}}'
$issueKey = Get-JiraIssueKeyFromPullRequestTitle $title

$transition = $IsDone ? 'Done' : ($IsResolve ? 'Resolve' : $null)

if ($null -eq $transition)
{
    Write-Error 'Unknown Jira issue transition was selected.'
    exit
}

$response = Invoke-JiraApiGet "issue/$issueKey/transitions"

$availableTransition = $response | Select-Object -ExpandProperty transitions | Where-Object { $PSItem.name -eq $transition }

if ($null -ne $availableTransition)
{
    Write-Output "Transition exists: $($availableTransition.id)."

    $bodyJson = @{
        transition = @{
            id = $availableTransition.id
        }
    } | ConvertTo-Json -Depth 3

    Invoke-JiraApiPost "issue/$issueKey/transitions" $bodyJson
}
else
{
    Write-Warning "The ""$transition"" transition is not available for the issue."
}
