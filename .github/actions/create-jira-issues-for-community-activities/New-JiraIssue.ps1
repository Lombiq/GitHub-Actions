[Diagnostics.CodeAnalysis.SuppressMessage(
    'PSReviewUnusedParameter',
    'Summary',
    Justification = 'It is actually used. This is a known issue: https://github.com/PowerShell/PSScriptAnalyzer/issues/1891.')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'Description', Justification = 'Same.')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'Type', Justification = 'Same.')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'IssueComponent', Justification = 'Same.')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'LinkUrl', Justification = 'Same.')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'LinkTitle', Justification = 'Same.')]
param
(
    $Summary,
    $Description,
    $Type,
    $IssueComponent,
    $LinkUrl,
    $LinkTitle
)

function CreateIssue
{
    $body = @{
        fields = @{
            project = @{
                key = $Env:JIRA_PROJECT_KEY
            }
            summary = $Summary
            description = $Description
            issuetype = @{
                name = $Type
            }
            labels = @('created-from-github')
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($IssueComponent))
    {
        $body.fields += @{
            components = @(
                @{
                    name = $IssueComponent
                }
            )
        }
    }

    $bodyJson = $body | ConvertTo-Json -Depth 9

    try
    {
        $response = Invoke-JiraApiPost 'issue' $bodyJson
        Write-Information "Jira issue created with the key $($response.key)." -InformationAction Continue
    }
    catch
    {
        Write-Error ("Failed to create the Jira issue with the following error: $($PSItem.Exception.Message) " +
            'If this seems like a temporary issue, try to rerun the workflow.')
        exit 1
    }

    # The "self" field in the response won't contain a public URL (but an API one) when the issue is created with a
    # service account. Neither will most of the fields in the response of GET-ting the issue. So, trying to extract it
    # from fields.priority.iconUrl.
    try
    {
        $issueDetails = Invoke-JiraApiGet "issue/$($response.key)"
        
        if ($issueDetails.fields.priority.iconUrl)
        {
            $iconUrl = $issueDetails.fields.priority.iconUrl
            if ($iconUrl -match '^(https?://[^/]+)')
            {
                $issueUrl = "$($matches[1])/browse/$($response.key)"
            }
        }
    }
    catch
    {
        Write-Warning "Failed to fetch issue details from Jira API. Falling back to constructed URL."
    }

    if (-not $issueUrl)
    {
        # Fallback to constructed URL if we couldn't extract it from the issue details. JIRA_BASE_URL won't be a public
        # URL when using service accounts, that's why we only use it as a fallback.
        $issueUrl = "$($Env:JIRA_BASE_URL.TrimEnd('/'))/browse/$($response.key)"
    }
    
    @{
        Key = $response.key
        Url = $issueUrl
    }
}

function AddLink
{
    param($IssueKey)

    $bodyJson = @{
        object = @{
            url = $LinkUrl
            title = $LinkTitle
        }
    } | ConvertTo-Json -Depth 3

    try
    {
        Invoke-JiraApiPost "issue/$IssueKey/remotelink" $bodyJson
    }
    catch
    {
        Write-Error ('Failed to add the link of the GitHub resource to the newly created Jira issue with the ' +
            "following error: $($PSItem.Exception.Message) The issue will need to be updated by hand.")
        exit 1
    }
}

$issue = CreateIssue
AddLink $issue.Key
Set-GitHubOutput 'issue-key' $issue.Key
Set-GitHubOutput 'issue-url' $issue.Url
