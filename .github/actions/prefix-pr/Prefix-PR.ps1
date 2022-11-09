param(
    [string] $Github_Repository,
    [string] $Github_Ref,
    [string] $Branch,
    [string] $Github_Token
)

$jiraBaseUrl = "https://lombiq.atlassian.net/browse/"
$owner, $repo = $Github_Repository.Split('/')
$prId = $Github_Ref -replace "refs\/pull\/(\d+)\/merge", '$1'

$url = "https://api.github.com/repos/$owner/$repo/pulls/$prId"
$headers = @{"Authorization" = "Bearer $Github_Token"; "Accept" = "application/vnd.github+json"}

$pr = Invoke-WebRequest $url -Headers $headers | % {$_.Content} | ConvertFrom-Json
$title = $pr.title
$body = $pr.body

$originalTitle = $title
$originalBody = $body

if ($Branch -NotLike "*issue*") {
    Exit
}

$issueKey = $Branch.replace("issue/", "")
$issueLink = "[$issueKey]($jiraBaseUrl$issuekey)"

if ($title -NotLike "*$issueKey*") {
    $title = $issueKey + ": " + $title
}

if (-Not $body) {
    $body = $issueLink
}
elseif ($body -NotLike "*$issueKey*") {
    $body = $issueLink + "`n" + $body
}
elseif ($body -NotLike "*``[$issueKey``]``($jiraBaseUrl$issuekey``)*") {
    $body = $body.replace($issueKey, $issueLink)
}

if (($title -ne $originalTitle) -or ($body -ne $originalBody)) {
    $bodyParams = @{"title" = $title; "body" = $body} | ConvertTo-Json
    Invoke-WebRequest $url -Headers $headers -Method Patch -Body $bodyParams
}
