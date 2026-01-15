param(
    [bool]$IsBreaking,
    [string]$Title,
    [string]$PullRequestNumber
)

$suffix = ' (⚠️ breaking changes)'

$currentTitle = $Title
$newTitle = $currentTitle

Write-Output "Current PR title: '$currentTitle'"
Write-Output "Is breaking changes: $IsBreaking"

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
        Write-Output 'Removing breaking changes suffix from PR title.'
        $newTitle = $currentTitle.Replace($suffix, '')
    }
}

if ($newTitle -ne $currentTitle)
{
    gh pr edit $PullRequestNumber --title $newTitle
}
