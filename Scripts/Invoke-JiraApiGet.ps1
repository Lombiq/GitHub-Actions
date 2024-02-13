param (
    [string]$ApiEndpoint
)

Invoke-JiraApiRequest -ApiEndpoint $ApiEndpoint -Method 'Get'
