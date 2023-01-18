# We need to fetch the PR details from the API as opposed to just using the context because a label added after the
# start of the run wouldn't be present in it.

[Diagnostics.CodeAnalysis.SuppressMessage(
    'PSReviewUnusedParameter',
    'Label1',
    Justification = 'False positive due to https://github.com/PowerShell/PSScriptAnalyzer/issues/1472.')]
[Diagnostics.CodeAnalysis.SuppressMessage(
    'PSReviewUnusedParameter',
    'Label2',
    Justification = 'False positive due to https://github.com/PowerShell/PSScriptAnalyzer/issues/1472.')]
param($Repository, $PullRequestNumber, $Label1, $Label2)

# See https://cli.github.com/manual/gh_pr_view
$content = gh api "repos/$Repository/pulls/$PullRequestNumber" | ConvertFrom-Json

$labelFound = $content.labels.Where({ $PSItem.name -eq $Label1 -or $PSItem.name -eq $Label2 }, 'First').Count -gt 0

Set-GitHubOutput 'contains-label' $labelFound
