param(
    [String[]] $CalledRepoBaseIncludeList,
    [String[]] $PathIncludeList,
    [String[]] $FileIncludeList,
    [String] $ExpectedRef
)

if ($CalledRepoBaseIncludeList.Count -eq 0)
{
    Write-Output '::warning file=Check-Called-GHA-refs.ps1,line10::CalledRepoBaseIncludeList is empty which is unexpected. If this was intentional, you can ignore this warning.'
    exit 0 # Nothing to check because array is empty.
}

$CalledRepoBaseIncludeList = $CalledRepoBaseIncludeList.ForEach({ 'uses:\s*' + $PSItem + '(.*)@(.*)' })

$matchedRefs = Get-ChildItem -Path $PathIncludeList -Include $FileIncludeList -Force -Recurse |
    Select-String -Pattern $CalledRepoBaseIncludeList 

if ($matchedRefs.Count -gt 0)
{

    "These called GitHub Actions and Workflows have been explicitly set to ref '$ExpectedRef'." >> $env:GITHUB_STEP_SUMMARY

    foreach ($matched in $matchedRefs)
    {
        $oldline = $matched.Line
        $newline = $matched.Line -Replace '@(.*)', "@$ExpectedRef"
        Write-Output $oldline
        Write-Output $newline

        $filename = $matched.RelativePath($pwd)

        (Get-Content $filename).Replace($oldline, $newline) | Set-Content $filename
    }
}
