<#
  .SYNOPSIS
  Tests if the pull request in the given repository, with the given number, has any of the two provided labels.

  .DESCRIPTION
  We need to fetch the PR details from the API as opposed to just using the context, because a label added after the
  start of the run wouldn't be present in it.

  .OUTPUTS
  Sets a boolean in the "contains-label" GitHub output variable.
#>

# This could support any number of labels in the future, but right now, we only need exactly two.
param($Repository, $PullRequestNumber, $Label1, $Label2)

$url = "https://api.github.com/repos/${{ github.repository }}/pulls/${{ github.event.pull_request.number }}"
$response = Invoke-WebRequest $url -Headers (Get-GitHubApiAuthorizationHeader) -Method Get
$content = $response | ConvertFrom-Json

$labelFound = $content.labels.Where({ $PSItem.name -eq $Label1 -or $PSItem.name -eq $Label2 }, 'First').Count -gt 0

Write-Output "Label found? $$labelFound"
Set-GitHubOutput "contains-label" $labelFound
