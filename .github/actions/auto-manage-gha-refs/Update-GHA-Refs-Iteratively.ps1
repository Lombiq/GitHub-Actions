param(
    [String] $LeftCommit,
    [String] $RightCommit,
    [String] $ExpectedRef,
    [String[]] $CalledRepoBaseIncludeList,
    [int] $MaxIterations = 10
)

# Function to get changed GHA items from git diff
function Get-ChangedGhaItems
{
    param(
        [String] $Left,
        [String] $Right,
        [String] $DiffFilter
    )

    Write-Output "Getting changed files between $Left and $Right with filter $DiffFilter..."
    
    $files = $(git diff --name-only --diff-filter=$DiffFilter $Left $Right)
    
    if ($files.Count -eq 0)
    {
        Write-Output "No files changed."
        return @()
    }

    Write-Output "Changed files: $($files -join ', ')"

    # Filter actions based on files in action directory.
    [array]$actionFiles = $files | Where-Object -FilterScript {
        try
        {
            $item = Get-Item $PSItem -ErrorAction Stop
            $itemDirectory = $item.Directory.FullName
        }
        catch
        {
            return $false
        }

        $isInGitHubDir = $itemDirectory -like '*/.github/*' -or $itemDirectory -eq '*/.github'
        if (-not $isInGitHubDir)
        {
            return $false
        }

        (Get-Item $PSItem).Directory.GetFiles('action.yml').Count -gt 0 -or
        (Get-Item $PSItem).Directory.GetFiles('action.yaml').Count -gt 0
    }

    # Get action directory names (de-duplicate).
    [array]$actions = $actionFiles.ForEach({ $PSItem.Replace('/' + $(Get-Item $PSItem).Name, '') }) | Select-Object -Unique

    # Filter workflow files.
    [array]$workflows = $files | Where-Object -FilterScript {
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
    
    Write-Output "GHA items changed: $($items -join ', ')"
    
    return $items
}

# Function to update references for specific items
function Update-ReferencesForItems
{
    param(
        [String[]] $Items,
        [String[]] $CalledRepoBase,
        [String] $TargetRef
    )

    if ($Items.Count -eq 0)
    {
        Write-Output "No items to update references for."
        return $false
    }

    Write-Output "Updating references for items: $($Items -join ', ')"

    $hasChanges = $false
    $repoBase = $CalledRepoBase[0]  # Assuming single repo for now.
    
    # Build patterns for the specific changed items.
    $patterns = $Items.ForEach({
        $item = $PSItem
        if ($item -like '*.yml' -or $item -like '*.yaml')
        {
            # Workflow file.
            "uses:\s*$repoBase/$item@(?<ref>[\w\.//-]*)"
        }
        else
        {
            # Action directory.
            "uses:\s*$repoBase/$item@(?<ref>[\w\.//-]*)"
        }
    })

    Write-Output "Searching for patterns in all .github files..."
    
    # Search all .github files for references to the changed items.
    $matchedRefs = @(Get-ChildItem -Path '.github' -Include '*.yml','*.yaml' -Force -Recurse) |
        Select-String -Pattern $patterns

    if ($matchedRefs.Count -gt 0)
    {
        Write-Output "Found $($matchedRefs.Count) references to update."
        
        foreach ($matched in $matchedRefs)
        {
            $oldRef = $matched.Matches[0].Groups['ref'].Value
            
            # Skip if already at target ref.
            if ($oldRef -eq $TargetRef)
            {
                continue
            }

            $oldline = $matched.Line
            $newline = $matched.Line -replace $oldRef, "$TargetRef"

            if ($oldline -ne $newline)
            {
                Write-Output "$oldline => $newline"

                $filename = $matched.RelativePath($PWD)
                $linenumber = $matched.LineNumber

                (Get-Content $filename).Replace($oldline, $newline) | Set-Content $filename

                Write-Output "::notice file=$filename,line=$linenumber,title=GHA Ref updated to '$TargetRef'::GHA Ref changed from '$oldRef' to '$TargetRef'"
                
                $hasChanges = $true
            }
        }
    }
    else
    {
        Write-Output "No references found to update."
    }

    return $hasChanges
}

# Main iterative loop.
Write-Output "Starting iterative GHA reference update process..."
Write-Output "Target ref: $ExpectedRef"
Write-Output "Comparing commits: $LeftCommit..$RightCommit"
Write-Output "Maximum iterations: $MaxIterations"
Write-Output ""

$currentLeftCommit = $LeftCommit
$iteration = 0
$totalChanges = $false

do
{
    $iteration++
    Write-Output "=== Iteration $iteration ==="
    
    # Get changed items between commits.
    $changedItems = Get-ChangedGhaItems -Left $currentLeftCommit -Right $RightCommit -DiffFilter 'ACMRT'
    
    if ($changedItems.Count -eq 0)
    {
        Write-Output "No GHA items changed in this iteration. Stopping."
        break
    }

    # Add repository prefix to items.
    $prefixedItems = $changedItems.ForEach({ Join-Path -Path $CalledRepoBaseIncludeList[0] -ChildPath $PSItem })
    
    # Update references to these changed items.
    $hasChanges = Update-ReferencesForItems -Items $prefixedItems -CalledRepoBase $CalledRepoBaseIncludeList -TargetRef $ExpectedRef
    
    if (-not $hasChanges)
    {
        Write-Output "No references were updated in this iteration. Process complete."
        break
    }

    $totalChanges = $true
    
    # Stage the changes.
    git add .github/
    
    # Check if there are any staged changes.
    $stagedChanges = git diff --cached --name-only
    
    if ($stagedChanges.Count -eq 0)
    {
        Write-Output "No changes to commit. Process complete."
        break
    }
    
    # Commit the changes (this creates a new commit to compare against).
    $commitMessage = "Auto-update GHA refs to $ExpectedRef (iteration $iteration)"
    git commit -m $commitMessage
    Write-Output "Committed changes: $commitMessage"
    
    # Update the left commit to the new commit we just made.
    $currentLeftCommit = 'HEAD~1'
    
    Write-Output ""
    
} while ($iteration -lt $MaxIterations)

if ($iteration -eq $MaxIterations)
{
    Write-Output "::warning::Reached maximum iterations ($MaxIterations). There may be more changes needed."
}

if ($totalChanges)
{
    Write-Output ""
    Write-Output "=== Summary ==="
    Write-Output "Total iterations: $iteration"
    Write-Output "GHA references have been updated to '$ExpectedRef'."
    Set-GitHubOutput 'has-changes' 'true'
}
else
{
    Write-Output ""
    Write-Output "=== Summary ==="
    Write-Output "No changes were needed."
    Set-GitHubOutput 'has-changes' 'false'
}
