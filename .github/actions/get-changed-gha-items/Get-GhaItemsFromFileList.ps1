param(
    [String[]] $FileIncludeList
)

# Filter actions based on files in action directory.
[array]$actionFiles = $FileIncludeList | Where-Object -FilterScript {
    $itemDirectory = (Get-Item $PSItem).Directory.FullName
    $isInGitHubDir = $itemDirectory -like '*/.github/*' -or $itemDirectory -eq '*/.github'
    if (-not $isInGitHubDir)
    {
        return $false
    }

    (Get-Item $PSItem).Directory.GetFiles('action.yml').Count -gt 0 -or
    (Get-Item $PSItem).Directory.GetFiles('action.yaml').Count -gt 0
}

# GitHub Actions are called by directory name. Get directory and de-duplicate list.
[array]$actions = $actionFiles.ForEach({ $PSItem.Replace('/' + $(Get-Item $PSItem).Name, '') }) | Select-Object -Unique

# Filter workflow files excluding action yaml file names.
[array]$workflows = $FileIncludeList | Where-Object -FilterScript {
    try
    {
        (Get-Item $PSItem).BaseName -ne 'action' -and
            ((Get-Item $PSItem).Extension -eq '.yml' -or
             (Get-Item $PSItem).Extension -eq '.yaml')
    }
    catch
    {
        return $false
    }
}

# Combine actions and workflows.
$items = $actions + $workflows

$output = 'changed-items=@(' + $($items | Join-String -DoubleQuote -Separator ',') + ')'
$output >> $env:GITHUB_OUTPUT
