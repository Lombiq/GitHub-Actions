param ($GitHub, $IssueComponent, $DiscussionJiraIssueDescription, $IssueJiraIssueDescription, $PullReqestJiraIssueDescription)

$context = [string]::IsNullOrEmpty($IssueComponent) ? $GitHub.repository : $IssueComponent
$titleSuffix = " in $context"

switch ($GitHub.event_name)
{
    "discussion"
    {
        $summary = "Respond to `"$($GitHub.event.discussion.title)`"$titleSuffix"
        $description = $DiscussionJiraIssueDescription
        $link = $GitHub.event.discussion.html_url
    }
    "issues"
    {
        $summary = "$($GitHub.event.issue.title)$titleSuffix"
        $description = $IssueJiraIssueDescription
        $link = $GitHub.event.issue.html_url

        foreach ($label in $GitHub.event.issue.labels)
        {
            $labelName = $label.name

            if ($labelName -eq "bug")
            {
                $type = "Bug"
                break
            }
            elseif ($labelName -eq "enhancement")
            {
                $type = "New Feature"
                break
            }
        }
    }
    "pull_request"
    {
        $summary = "Review `"$($GitHub.event.pull_request.title)`"$titleSuffix"
        $description = $PullReqestJiraIssueDescription
        $link = $GitHub.event.pull_request.html_url
    }
    default
    {
        $message = "Unknown event `"$($GitHub.event_name)`". Please only call this script for one of the following " +
            "events: discussion, issues, pull_request."
        Write-Error $message
    }
}

if ($null -eq $type)
{
    $type = "Task"
}

Write-Output "::set-output name=summary::$summary"
Write-Output "::set-output name=jsonDescription::$($description | ConvertTo-Json)"
Write-Output "::set-output name=type::$type"
Write-Output "::set-output name=link::$link"
