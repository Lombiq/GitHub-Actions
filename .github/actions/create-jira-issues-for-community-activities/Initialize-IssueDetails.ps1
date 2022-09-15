param ($GitHub)

switch ($GitHub.event_name)
{
    "discussion"
    {
        $summary = "Respond to `"$($GitHub.event.discussion.title)`""
        $description = $Env:DISCUSSION_JIRA_ISSUE_DESCRIPTION
        $link = $GitHub.event.discussion.html_url
    }
    "issues"
    {
        $summary = "$($GitHub.event.issue.title) in $($GitHub.repository)"
        $description = $Env:ISSUE_JIRA_ISSUE_DESCRIPTION
        $link = $GitHub.event.issue.html_url

        $i = 0
        while($i -lt $GitHub.event.issue.labels.Length -and $null -eq $type)
        {
            $labelName = $GitHub.event.issue.labels[$i].name

            if ($labelName -eq "bug")
            {
                $type = "Bug"
            }
            elseif ($labelName -eq "enhancement")
            {
                $type = "New Feature"
            }

            $i++
        }
    }
    "pull_request"
    {
        $summary = "Review `"$($GitHub.event.pull_request.title)`""
        $description = $Env:PULL_REQUEST_JIRA_ISSUE_DESCRIPTION
        $link = $GitHub.event.pull_request.html_url
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
