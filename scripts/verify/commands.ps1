
<#
.Synopsis
Fails the current step with the provided message. Same as "core.setFailed()" from the official
toolkit (https://github.com/actions/toolkit).
#>
function Set-Failed([Parameter(Mandatory = $True)] [string] $Message)
{
    Write-Output "::error::$Message"
    exit 1
}

<#
.Synopsis
Checks if the current pull request title matches expectations and exits with success or an error 
message and failure.
#>
function Exit-EnsureCurrentPullRequest([Parameter(Mandatory = $True)] [string] $title)
{
    if ($title -match '^\s*\w+-\d+\s*:') { exit 0 }
    Set-Failed 'The pull request title is not in the expected format. Please start with the issue code followed by a colon and the title, e.g. "PROJ-123: My PR Title".'
}

<#
.Synopsis
Checks if a parent pull request exists in the given repo with the expected title and exits with 
success or an error message and failure.
#>
function Exit-EnsureParentPullRequest(
    [Parameter(Mandatory = $True)] [string] $repo,
    [Parameter(Mandatory = $True)] [string] $title)
{
    $url = "https://api.github.com/repos/$repo/pulls?state=open&per_page=100"
    $titles = curl -s -H 'Accept: application/vnd.github.v3+json' $url | ConvertFrom-Json | % { $_.title }

    $issueCode = $title -replace '^\s*(\w+-\d+)\s*:.*$', '$1'
    $lookFor = "${issueCode}:"
    if (($titles | ? { $_ -and $_.Trim().StartsWith($lookFor) }).Count -gt 0) { exit 0 }
    Set-Failed "Couldn't find any Open-Source-Orchard-Core-Extensions pull request whose title starts with `"$lookFor`". Please create one."
}