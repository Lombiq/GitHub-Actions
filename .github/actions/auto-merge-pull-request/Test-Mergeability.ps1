param ($Response)

if ($Response.StatusCode -ne 200)
{
    Write-Output "Getting the pull request details failed with HTTP $($Response.StatusCode)."
    exit 1
}


$content = $Response | ConvertFrom-Json
$labelFound = $content.labels.Where({ $PSItem.name -eq 'auto-merge-if-checks-succeed' }, 'First').Count -gt 0

Set-GitHubOutput "is-mergeable" $labelFound
