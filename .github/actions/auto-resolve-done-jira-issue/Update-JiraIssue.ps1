param($Repository, $PullRequestNumber, $IsDone, $IsResolve)

# We need to fetch the PR details using the CLI (see https://cli.github.com/manual/gh_pr_view) as opposed to just using
# the context, because the title may have changed (by the user or the add-jira-issue-code-to-pull-request action) after
# the start of the run and that wouldn't be present in it.
$title = gh pr view $PullRequestNumber --repo $Repository --json title --template '{{.title}}'
$issueKey = Get-JiraIssueKeyFromPullRequestTitle $title

$transition = $IsDone ? 'Done' : ($IsResolve ? 'Resolve' : $null)

if ($transition -eq $null)
{
    Write-Error 'Unknown Jira issue transition was selected.'
    exit
}

$headers = @{
    'apikey' = $Env:JIRA_API_KEY
    'Content-Type' = 'application/json'
    'Accept' = 'application/json'
}

$body = @{
    options = @{
        method = 'GET'
        headers = @{
            'Content-Type' = 'application/json'
            'Accept' = 'application/json'
        }
    }
    url = "/rest/api/3/issue/$issueKey/transitions"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri $Env:JIRA_ENDPOINT_URL -Method Get -Headers $headers -Body $body

$availableTransition = $response | Select-Object -ExpandProperty transitions | Where-Object { $_.name -eq $transition }

if ($availableTransition -ne $null)
{
    Write-Host "Transition exists. $($availableTransition.id)"

    $body = @{
        options = @{
            method = 'POST'
            headers = @{
                'Content-Type' = 'application/json'
                'Accept' = 'application/json'
            }
            body = @{
                transition = @{
                    id = $availableTransition.id
                }
            }
        }
        url = "/rest/api/3/issue/$issueKey/transitions"
    } | ConvertTo-Json -Depth 3

    $response = Invoke-RestMethod -Uri $Env:JIRA_ENDPOINT_URL -Method Post -Headers $headers -Body $body
}
else
{
    Write-Warning "The ""$transition"" transition is not available for the issue."
}
