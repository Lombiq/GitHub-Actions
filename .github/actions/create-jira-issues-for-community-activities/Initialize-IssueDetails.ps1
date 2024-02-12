param
(
    $GitHub,
    $IssueComponent,
    $SuffixIssueTitles,
    $DiscussionJiraIssueDescription,
    $IssueJiraIssueDescription,
    $PullRequestJiraIssueDescription
)

$context = [string]::IsNullOrEmpty($IssueComponent) ? $GitHub.repository : $IssueComponent
$titleSuffix = $SuffixIssueTitles ? " in $context" : ''
Write-Output "Suffix: $titleSuffix"

switch ($GitHub.event_name)
{
    'discussion'
    {
        $summary = "Respond to `"$($GitHub.event.discussion.title)`"$titleSuffix"
        $description = $DiscussionJiraIssueDescription
        $linkUrl = $GitHub.event.discussion.html_url
        $linkTitle = 'GitHub discussion'
    }
    'issues'
    {
        $summary = "$($GitHub.event.issue.title)$titleSuffix"
        $description = $IssueJiraIssueDescription
        $linkUrl = $GitHub.event.issue.html_url
        $linkTitle = 'GitHub issue'

        foreach ($label in $GitHub.event.issue.labels)
        {
            $labelName = $label.name

            if ($labelName -eq 'bug')
            {
                $type = 'Bug'
                break
            }
            elseif ($labelName -eq 'enhancement')
            {
                $type = 'New Feature'
                break
            }
        }
    }
    'pull_request'
    {
        $summary = "Review `"$($GitHub.event.pull_request.title)`"$titleSuffix"
        $description = $PullRequestJiraIssueDescription
        $linkUrl = $GitHub.event.pull_request.html_url
        $linkTitle = 'GitHub pull request'
    }
    default
    {
        $message = @(
            "Unknown event `"$($GitHub.event_name)`". Please only call this script for one of the following events:"
            'discussion, issues, pull_request_target.'
        ) -join ' '
        Write-Error "::error::$message"
        exit 1
    }
}

if ($null -eq $type)
{
    $type = 'Task'
}

[PSCustomObject]@{
    Summary = $summary
    Description = $description
    Type = $type
    LinkUrl = $linkUrl
    LinkTitle = $linkTitle
}
