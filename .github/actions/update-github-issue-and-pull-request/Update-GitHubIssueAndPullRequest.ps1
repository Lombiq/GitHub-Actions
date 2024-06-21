﻿param(
    [string] $JiraBaseUrl,
    [string] $GitHubRepository,
    [string] $Branch,
    [string] $Title,
    [string] $Body,
    [string] $Assignee,
    [string] $PullRequestId
)

$jiraBrowseUrl = $JiraBaseUrl.TrimEnd('/') + '/browse/'

$originalTitle = $Title
$originalBody = $Body

if ($Branch -NotLike '*issue*')
{
    Exit
}

$Branch -match '(\w+-\d+)' | Out-Null

if ($null -eq $Matches)
{
    throw "Issue key not found in the branch name '$Branch'!"
}

$issueKey = $Matches[0]
$issueLink = "[$issueKey]($jiraBrowseUrl$issuekey)"

if ($Title -NotLike "*$issueKey*")
{
    $Title = $issueKey + ': ' + $Title
}

if (-Not $Body)
{
    $Body = $issueLink
}
elseif ($Body -NotLike "*$issueKey*")
{
    $Body = $issueLink + "`n" + $Body
}
elseif ($Body -NotLike "*``[$issueKey``]``($jiraBrowseUrl$issuekey``)*")
{
    $Body = $Body.replace($issueKey, $issueLink)
}

if ((gh repo view $GitHubRepository --json hasIssuesEnabled | ConvertFrom-Json).hasIssuesEnabled)
{
    $issueQuery = "$issueKey in:title"
    $output = gh issue list --search $issueQuery --repo $GitHubRepository
    $issueItem = ($output | Select-Object -First 1)

    if ($issueItem)
    {
        $issueNumber = $issueItem -split '\t' | Select-Object -First 1
        $fixesIssue = "Fixes #$issueNumber"

        if ($Body -NotLike "*$fixesIssue*")
        {
            $Body = "$Body`n$fixesIssue"
        }

        if ($issueNumber)
        {
            gh api -X PATCH "/repos/$GitHubRepository/issues/$issueNumber" -f "assignee=$Assignee"
        }
    }
    else
    {
        Write-Output "No issue was found with the query '$issueQuery' in the repository '$GitHubRepository'."
    }
}
else
{
    Write-Output "Issues are disabled in the '$GitHubRepository' repository."
}

if (($Title -ne $originalTitle) -or ($Body -ne $originalBody))
{
    # Escape the quote characters. This is necessary because PowerShell mangles the quote characters when passing
    # arguments into a native command such as the GitHub CLI. See https://github.com/cli/cli/issues/3425 for details.
    $Title = $Title -replace '"', '\"'
    $Body = $Body -replace '"', '\"'

    # See https://cli.github.com/manual/gh_pr_edit
    gh pr edit $PullRequestId --title $Title --body $Body --repo $GitHubRepository
}
