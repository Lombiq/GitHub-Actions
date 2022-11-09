param(
    [string] $Github_Repository,
    [string] $Github_Ref,
    [string] $Github_Token
)

$jiraBaseUrl = "https://lombiq.atlassian.net/browse/"
Write-Output ${$Github_Ref##*/}

$owner, $repo = $Github_Repository.Split('/')
Write-Output $owner
Write-Output $repo


# $url = "https://api.github.com/repos/Lombiq/Github-Actions/pulls/90"
# $headers = @{"Authorization" = "Bearer $Github_Token"; "Accept" = "application/vnd.github+json"}

# $pr = Invoke-WebRequest $url -Headers $headers | % {$_.Content} | ConvertFrom-Json
# $title = $pr.title
# $body = $pr.body

# $originalTitle = $title
# $originalBody = $body

# $branch = "issue/OSOE-425"
# if ($branch -NotLike "*issue*") {
#     Exit
# }

# $issueKey = $branch.replace("issue/", "")
# $issueLink = "[$issueKey]($jiraBaseUrl$issuekey)"

# if ($title -NotLike "*$issueKey*") {
#     $title = $issueKey + ": " + $title
# }

# if (-Not $body) {
#     $body = $issueLink
# }
# elseif ($body -NotLike "*$issueKey*") {
#     $body = $issueLink + "`n" + $body
# }
# elseif ($body -NotLike "*``[$issueKey``]``($jiraBaseUrl$issuekey``)*") {
#     $body = $body.replace($issueKey, $issueLink)
# }

# if (($title -ne $originalTitle) -or ($body -ne $originalBody)) {
#     $bodyParams = @{"title" = $title; "body" = $body}
#     Invoke-WebRequest $url -Headers $headers -Method Patch -Body $bodyParams
# } else {
#     Write-Output "Nothing was changed"
# }

# Write-Output "End of file."
