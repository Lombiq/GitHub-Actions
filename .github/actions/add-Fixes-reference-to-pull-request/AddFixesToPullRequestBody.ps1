param(
    [string] $Body,
    [string] $GitHubRepository,
    [string] $PullRequestId
)

$jira_Key = if ("$Body" -match '\[(.*?)\]')
{
    $Matches[1]
}
else
{
    'No_Key_added'
}

$originalBody = $Body
$issueQuery = "$jira_Key in:title"
$output = gh issue list --search $issueQuery --repo $GitHubRepository
$firstItem = ($output | Select-Object -First 1)

if (-Not $firstItem)
{
    Write-Output "No issue was found related to the Jira issue '$jira_Key' in the repository '$GitHubRepository'"
    Exit
}

$issueNumber = $firstItem -split '\t' | Select-Object -First 1
$fixsIssue = "Fixes #$issueNumber"

elseif ($Body -NotLike "*$fixsIssue*")
{
    $Body = $Body + "`n" + $fixsIssue
}

if ($Body -ne $originalBody)
{
    # Escape the quote characters. This is necessary because PowerShell mangles the quote characters when passing
    # arguments into a native command such as the GitHub CLI. See https://github.com/cli/cli/issues/3425 for details.
    $Body = $Body -replace '"', '\"'

    # See https://cli.github.com/manual/gh_pr_edit
    gh pr edit $PullRequestId --body $Body --repo $GitHubRepository
}
