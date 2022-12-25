param(
    [string] $Repository,
    [string] $Branch
)

if (!($Branch -match '(\w+-\d+)'))
{
    exit
}

$url = "https://api.github.com/repos/$Repository/pulls?state=open&per_page=100"
$response = Invoke-WebRequest $url -Headers (Get-GitHubApiAuthorizationHeader) -Method Get
$titles = $response.Content | ConvertFrom-Json | ForEach-Object { $PSItem.title }

$issueCode = $matches[0]
$lookFor = "${issueCode}:"
if (($titles | Where-Object { $PSItem -and $PSItem.Trim().StartsWith($lookFor) }).Count -gt 0) { exit 0 }
Set-Failed "Couldn't find any pull request whose title starts with `"$lookFor`" in $Repository. Please create one."
