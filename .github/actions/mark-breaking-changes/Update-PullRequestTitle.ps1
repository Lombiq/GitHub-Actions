param(
    [bool]$IsBreaking,
    [string]$Title,
    [string]$PullRequestNumber
)

$suffix = ' (⚠️ breaking changes)'

$currentTitle = $Title
$newTitle = $currentTitle

if ($IsBreaking)
{
    if (-not $currentTitle.Contains($suffix))
    {
        $newTitle = $currentTitle + $suffix
    }
}
else
{
    if ($currentTitle.Contains($suffix))
    {
        $newTitle = $currentTitle.Substring(0, $currentTitle.Length - $suffix.Length)
    }
}

if ($newTitle -ne $currentTitle)
{
    gh pr edit $PullRequestNumber --title $newTitle
}
