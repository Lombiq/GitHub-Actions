param ($GitHub)

switch ($GitHub.event_name)
{
    "discussion"
    {
        $summary = "Respond to `"$($GitHub.event.discussion.title)`""
        $description = $Env:DISCUSSION_JIRA_ISSUE_DESCRIPTION
    }
    "issues"
    {
        $summary = "$($GitHub.event.issue.title) in $($GitHub.repository)"
        $description = $Env:ISSUE_JIRA_ISSUE_DESCRIPTION

        $i = 0
        while($i -lt $GitHub.labels.Length -and $type -eq $null)
        {
            $labelName = $GitHub.labels[$i].name

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
    }
}

if ($type -eq $null)
{
    $type = "Task"
}

Write-Output "::set-output name=summary::$summary"
$jsonDescription = $description | ConvertTo-Json
Write-Output "::set-output name=jsonDescription::$jsonDescription"
Write-Output "::set-output name=type::$type"
