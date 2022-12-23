param(
    [string] $Repository,
    [string] $Branch
)

$url = "https://api.github.com/repos/Lombiq/GitHub-Actions/pulls/159"
$response = Invoke-WebRequest $url -Headers (Get-GitHubApiAuthorizationHeader) -Method Get
$content = $response | ConvertFrom-Json
Write-Output "Content: $content"

$url = "https://api.github.com/repos/Lombiq/GitHub-Actions/pulls?state=open&per_page=100"
Write-Output $url
$response = Invoke-WebRequest $url -Headers (Get-GitHubApiAuthorizationHeader) -Method Get
$titles = $response.Content | ConvertFrom-Json | ForEach-Object { $PSItem.title }

if (!($Branch -match '(\w+-\d+)'))
{
    exit
}

$issueCode = $matches[0]
$lookFor = "${issueCode}:"
if (($titles | Where-Object { $PSItem -and $PSItem.Trim().StartsWith($lookFor) }).Count -gt 0) { exit 0 }
Set-Failed "Couldn't find any pull request whose title starts with `"$lookFor`" in $Repository. Please create one."
