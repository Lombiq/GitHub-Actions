param(
    [string] $Repository,
    [string] $Branch
)

$url = "https://api.github.com/repos/Lombiq/GitHub-Actions/pulls/159"
$response = Invoke-WebRequest $url -Headers (Get-GitHubApiAuthorizationHeader) -Method Get
$content = $response | ConvertFrom-Json
Write-Output "Content: $content"


