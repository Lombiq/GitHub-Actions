param(
    [string] $JiraBaseUrl,
    [string] $GitHubRepository,
    [string] $Branch,
    [string] $GitHubToken,
    [string] $Title,
    [string] $Body,
    [string] $PullRequestId
)

$jiraBaseUrl = $JiraBaseUrl + '/browse/';
$owner, $repo = $GitHubRepository.Split('/')

$originalTitle = $Title
$originalBody = $Body

if ($Branch -NotLike "*issue*") {
    Exit
}

$Branch -match '(\w+-\d+)'
$issueKey = $matches[0]
$issueLink = "[$issueKey]($jiraBaseUrl$issuekey)"

if ($Title -NotLike "*$issueKey*") {
    $Title = $issueKey + ": " + $Title
}

if (-Not $Body) {
    $Body = $issueLink
}
elseif ($Body -NotLike "*$issueKey*") {
    $Body = $issueLink + "`n" + $Body
}
elseif ($Body -NotLike "*``[$issueKey``]``($jiraBaseUrl$issuekey``)*") {
    $Body = $Body.replace($issueKey, $issueLink)
}

if (($Title -ne $originalTitle) -or ($Body -ne $originalBody)) {
    $bodyParams = @{"title" = $Title; "body" = $Body} | ConvertTo-Json
    $url = "https://api.github.com/repos/$owner/$repo/pulls/$PullRequestId"
    $headers = @{"Authorization" = "Bearer $GitHubToken"; "Accept" = "application/vnd.github+json"}
    Invoke-WebRequest $url -Headers $headers -Method Patch -Body $bodyParams
}
