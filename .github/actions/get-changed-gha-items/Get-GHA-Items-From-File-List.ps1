param(
    [String[]] $FileIncludeList
)

# Filter actions based on files in action directory.
[array]$actionFiles = $FileIncludeList | Where-Object -FilterScript {
    try
    {
        (Get-Item $PSitem).Directory.GetFiles('action.yml').Count -gt 0 -or
        (Get-Item $PSitem).Directory.GetFiles('action.yaml').Count -gt 0
    }
    catch
    {
        return $false
    }
}

# GitHub Actions are called by directory name. Get directory and de-duplicate list.
[array]$actions = $actionFiles.ForEach({ $PSItem.Replace('/' + $(Get-Item $PSItem).Name, '') }) | Select-Object -Unique

# Filter workflow files excluding action yaml file names.
[array]$workflows = $FileIncludeList | Where-Object -FilterScript {
    try
    {
        (Get-Item $PSitem).BaseName -ne 'action' -and
            ((Get-Item $PSitem).Extension -eq '.yml' -or
             (Get-Item $PSitem).Extension -eq '.yaml')
    }
    catch {
        return $false
    }
}

# Combine actions and workflows.
$items = $actions + $workflows

$output = 'changed-items=@(' + $($items | Join-String -DoubleQuote -Separator ',') + ')'
$output >> $env:GITHUB_OUTPUT
