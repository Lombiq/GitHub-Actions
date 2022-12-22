param(
    [string] $Repository,
    [string] $Branch
)

$requestParameters = @{
    Uri = "https://api.github.com/repos/$Repository/pulls?state=open&per_page=100"
    Method = "Get"
    Headers = Get-GitHubApiAuthorizationHeader
}
$titles = (Invoke-WebRequest @requestParameters).Content | ConvertFrom-Json | ForEach-Object { $PSItem.title }

if (!($Branch -match '(\w+-\d+)'))
{
    exit
}

$issueCode = $matches[0]
$lookFor = "${issueCode}:"
if (($titles | Where-Object { $PSItem -and $PSItem.Trim().StartsWith($lookFor) }).Count -gt 0) { exit 0 }
Set-Failed "Couldn't find any pull request whose title starts with `"$lookFor`" in $Repository. Please create one."
