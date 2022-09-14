param ($GitHub)

switch ($GitHub.event_name)
{
    "discussion"
    {
        $summary = "Respond to `"$GitHub.event.discussion.title`""
    }
    "issues"
    {
        $summary = "$GitHub.event.issue.title in $GitHub.repository"

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
        $summary = "Review `"$GitHub.event.pull_request.title`""
    }
}

if ($type -eq $null)
{
    $type = "Task"
}

Write-Output "::set-output name=summary::$summary"
Write-Output "::set-output name=type::$type"
