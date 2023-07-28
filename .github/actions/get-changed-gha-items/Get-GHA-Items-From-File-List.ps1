param(
    [String[]] $FileIncludeList
)

# Filter actions based on files in action directory.
$actionFiles = $FileIncludeList | Where-Object -FilterScript { 
    (Get-Item $PSitem).Directory.GetFiles("action.yml").Count -gt 0 -or
    (Get-Item $PSitem).Directory.GetFiles("action.yaml").Count -gt 0
}

# GitHub Actions are called by directory name. Get directory and de-duplicate list.
$actions = $actionFiles.ForEach({ $PSItem.Replace("/" + $(Get-Item $PSItem).Name, "") }) | select -Unique

# Filter workflow files excluding action yaml file names.
$workflows = $FileIncludeList | Where-Object -FilterScript { 
    (Get-Item $PSitem).BaseName -ne "action" -and 
        ((Get-Item $PSitem).Extension -eq ".yml" -or 
         (Get-Item $PSitem).Extension -eq ".yaml")
}

# Combine actions are workflows.
$items = $actions + $workflows

$output = "changed-items=@(" + $($items | Join-String -DoubleQuote -Separator ',') + ")"
Write-Output "output=$output"
$output >> $env:GITHUB_OUTPUT
