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

Write-Output "Header:"
Write-Output (Get-GitHubApiAuthorizationHeader)

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
    $bodyParams = @{"title" = $Title; "body" = $Body } | ConvertTo-Json
    $url = "https://api.github.com/repos/$GitHubRepository/pulls/$PullRequestId"
    Invoke-WebRequest $url -Headers (Get-GitHubApiAuthorizationHeader) -Method Patch -Body $bodyParams
}
