param(
    [string] $Repository,
    [string] $Branch
)

if (-not ($Branch -match '(\w+-\d+)'))
{
    exit
}

# See https://cli.github.com/manual/gh_pr_list and https://cli.github.com/manual/gh_help_formatting
$titles = gh pr list --repo $Repository --limit 100 --json title --template '{{range .}}{{tablerow .title}}{{end}}'

$issueCode = $Matches[0]
$lookFor = "$($issueCode):"
if (($titles | Where-Object { $PSItem -and $PSItem.Trim().StartsWith($lookFor) }).Count -gt 0) { exit 0 }
Set-Failed "Couldn't find any pull request whose title starts with `"$lookFor`" in $Repository. Please create one."
