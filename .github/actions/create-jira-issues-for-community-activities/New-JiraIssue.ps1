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

    $response = Invoke-JiraApiPost 'issue' $bodyJson

    Write-Information "Jira issue created with the key $($response.key)." -InformationAction Continue

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

    Invoke-JiraApiPost "issue/$issueKey/remotelink" $bodyJson
}

$issueKey = CreateIssue
AddLink $issueKey
Set-GitHubOutput 'issue-key' $issueKey
Set-GitHubOutput 'issue-url' "$($Env:JIRA_BASE_URL.TrimEnd('/'))/browse/$issueKey"
