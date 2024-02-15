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
        $message = "Failed to create the Jira issue with the following error: $($PSItem.Exception.Message) " +
            'If this seems like a temporary issue, try to rerun the workflow.'
        Write-Error $message
        exit 1
    }

    $response.key
}

function AddLink
{
    param($issueKey)

    $bodyJson = @{
        object = @{
            url = $LinkUrl
            title = $LinkTitle
        }
    } | ConvertTo-Json -Depth 3

    try
    {
        Invoke-JiraApiPost "issue/$issueKey/remotelink" $bodyJson
    }
    catch
    {
        $message = 'Failed to add the link of the GitHub resource to the newly created Jira issue with the following ' +
            "error: $($PSItem.Exception.Message) The issue will need to be updated by hand."
        Write-Error $message
        exit 1
    }
}

$issueKey = CreateIssue
AddLink $issueKey
Set-GitHubOutput 'issue-key' $issueKey
Set-GitHubOutput 'issue-url' "$($Env:JIRA_BASE_URL.TrimEnd('/'))/browse/$issueKey"
