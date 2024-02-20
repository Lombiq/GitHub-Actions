param (
    [string]$ApiEndpoint,
    [string]$BodyJson
)

Invoke-JiraApiRequest -ApiEndpoint $ApiEndpoint -Method 'Post' -BodyJson $BodyJson
