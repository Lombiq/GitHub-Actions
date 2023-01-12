param(
    [string] $JiraBaseUrl,
    [string] $GitHubRepository,
    [string] $Branch,
    [string] $Title,
    [string] $Body,
    [string] $PullRequestId
)

$jiraBrowseUrl = $JiraBaseUrl + '/browse/';

$originalTitle = $Title
$originalBody = $Body

if ($Branch -NotLike "*issue*")
{
    Exit
}

$Branch -match '(\w+-\d+)'
$issueKey = $matches[0]
$issueLink = "[$issueKey]($jiraBrowseUrl$issuekey)"

if ($Title -NotLike "*$issueKey*")
{
    $Title = $issueKey + ": " + $Title
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

if (($Title -ne $originalTitle) -or ($Body -ne $originalBody))
{
    # See https://cli.github.com/manual/gh_pr_edit
    Write-Output "gh pr edit `"$PullRequestId`" --title `"$Title`" --body `"$Body`" --repo `"$GitHubRepository`""
    gh pr edit $PullRequestId --title "$Title" --body "$Body" --repo "$GitHubRepository"
}
