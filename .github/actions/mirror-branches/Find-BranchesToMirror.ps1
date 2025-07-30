param(
    [string] $BranchNames,
    [string] $BranchRegex,
    [string] $SourceRepository,
    [string] $SourceBranchesJson,
    [string] $DestinationRepository,
    [string] $DestinationBranchesJson
)

$BranchNames = $BranchNames.Trim()
$BranchRegex = $BranchRegex.Trim()

if ($BranchNames)
{
    $branchNameList = $BranchNames -split ',' | ForEach-Object { $PSItem.Trim() } | Where-Object { $PSItem -ne '' }
    $branchNameRegexes = $branchNameList | ForEach-Object { "^$($PSItem.Replace('/', '\/'))$" }
    $BranchRegex = $branchNameRegexes -join '|'
}

$sourceBranchHashes = [System.Collections.Generic.Dictionary[string, string]]::new()
$SourceBranchesJson | ConvertFrom-Json | ForEach-Object { $sourceBranchHashes[$PSItem.name] = $PSItem.commit.sha }
if ($sourceBranchHashes.Count -eq 0)
{
    Write-Output "::error::Source repository '$SourceRepository' has no branches!"
    exit 1
}

$matchingSourceBranchNames = $sourceBranchHashes.Keys | Where-Object { $PSItem -match $BranchRegex }
if ($matchingSourceBranchNames.Count -gt 0)
{
    Write-Output ("::notice::Found $($matchingSourceBranchNames.Count) branches in '$SourceRepository' (source) matching '$BranchRegex': " +
        ($matchingSourceBranchNames -join ', '))
}
else
{
    Write-Output "::error::There are no branches in '$SourceRepository' matching '$BranchRegex'!"
    exit 1
}

$destinationBranchHashes = [System.Collections.Generic.Dictionary[string, string]]::new()
$DestinationBranchesJson | ConvertFrom-Json | ForEach-Object { $destinationBranchHashes[$PSItem.name] = $PSItem.commit.sha }
$mirroringBranchNames = @()
foreach ($branch in $matchingSourceBranchNames)
{
    if (-not $destinationBranchHashes.ContainsKey($branch) -or $sourceBranchHashes[$branch] -ne $destinationBranchHashes[$branch])
    {
        $mirroringBranchNames += $branch
    }
}

if ($mirroringBranchNames.Count -gt 0)
{
    Write-Output ("::notice::Found $($mirroringBranchNames.Count) branches in '$DestinationRepository' (destination) to be updated: " +
        ($mirroringBranchNames -join ', '))
}
else
{
    Write-Output "::notice::All the matched branches are up-to-date in '$DestinationRepository'."
}

Set-GitHubOutput 'first-branch-name' $mirroringBranchNames[0]
Set-GitHubOutput 'branch-names' ($mirroringBranchNames -join ',')
