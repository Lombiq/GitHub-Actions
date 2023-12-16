param
(
    $Summary,
    $Description,
    $Type,
    $IssueComponent,
    $LinkUrl,
    $LinkTitle
)

$headers = @{
    'apikey' = $Env:JIRA_API_KEY
    'Content-Type' = 'application/json'
    'Accept' = 'application/json'
}

function CreateIssue {
    $body = @{
        options = @{
            method = 'POST'
            headers = @{
                'Content-Type' = 'application/json'
                'Accept' = 'application/json'
            }
            body = @{
                fields = @{
                    project = @{
                        key = $Env:JIRA_PROJECT_KEY
                    }
                    summary = $Summary
                    description = @{
                        type = 'doc'
                        version = 1
                        content = @(
                            @{
                                type = 'paragraph'
                                content = @(
                                    @{
                                        type = 'text'
                                        text = $Description
                                    }
                                )
                            }
                        )
                    }
                    issuetype = @{
                        name = $Type
                    }
                    labels = @('created-from-github')
                }
            }
        }
        url = "/rest/api/3/issue"
    }
    
    if (-not [string]::IsNullOrWhiteSpace($IssueComponent)) {
        $body.options.body.fields += @{
            components = @(@{
                name = $IssueComponent
            })
        }
    }
    
    $body = $body | ConvertTo-Json -Depth 9

    $response = Invoke-RestMethod -Uri $Env:JIRA_ENDPOINT_URL -Method Post -Headers $headers -Body $body
    Write-Information "Jira issue created with the key $($response.key)." -InformationAction Continue
    $response.key
}

function AddLink {
    param($issueKey)

    $body = @{
        options = @{
            method = 'POST'
            headers = @{
                'Content-Type' = 'application/json'
                'Accept' = 'application/json'
            }
            body = @{
                object = @{
                    url = $LinkUrl
                    title = $LinkTitle
                }
            }
        }
        url = "/rest/api/3/issue/$issueKey/remotelink"
    } | ConvertTo-Json -Depth 3
    
    Invoke-RestMethod -Uri $Env:JIRA_ENDPOINT_URL -Method Post -Headers $headers -Body $body
}

function GetIssueUrl {
    param($issueKey)

    $body = @{
        options = @{
            method = 'GET'
            headers = @{
                'Content-Type' = 'application/json'
                'Accept' = 'application/json'
            }
        }
        url = "/rest/api/3/serverInfo"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $Env:JIRA_ENDPOINT_URL -Method Get -Headers $headers -Body $body

    "$($response.baseUrl)/browse/$issueKey"
}

$issueKey = CreateIssue
AddLink $issueKey
Set-GitHubOutput 'issue-url' (GetIssueUrl $issueKey)
