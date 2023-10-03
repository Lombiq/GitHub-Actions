param(
    [String[]] $CalledRepoBaseIncludeList,
    [String[]] $PathIncludeList,
    [String[]] $FileIncludeList,
    [String] $ExpectedRef,
    [String] $GitHubRepository,
    [String] $GitHubRefName
)

if ($CalledRepoBaseIncludeList.Count -eq 0)
{
    Write-Output '::warning file=Check-Called-GHA-refs.ps1,line10::CalledRepoBaseIncludeList is empty which is unexpected. If this was intentional, you can ignore this warning.'
    exit 0 # Nothing to check because array is empty.
}

$CalledRepoBaseIncludeList = $CalledRepoBaseIncludeList.ForEach({ 'uses:\s*' + $PSItem })

$mismatchRefs = Get-ChildItem -Path $PathIncludeList -Include $FileIncludeList -Force -Recurse |
    Select-String -Pattern $CalledRepoBaseIncludeList |
    Select-String -Pattern $ExpectedRef -NotMatch

if ($mismatchRefs.Count -gt 0)
{
    "These called GitHub Actions and Workflows do not match expected ref '$ExpectedRef'." >> $env:GITHUB_STEP_SUMMARY

    foreach ($mismatch in $mismatchRefs)
    {
        $filename = $mismatch.RelativePath($pwd)
        $linenumber = $mismatch.LineNumber
        $title = $mismatch.Line

        # The below statement won't work becuase actions/toolkit will not link to files that are not part of the commit.
        # See: https://github.com/actions/toolkit/issues/470
        # Write-Output "::error file=$filename,line=$linenumber,title=$title::GHA Ref does not match '$ExpectedRef'"

        # As a workaround, link directly to file.
        "- <a href='https://github.com/$GitHubRepository/blob/$GitHubRefName/$filename#L$linenumber'>$filename#L$linenumber</a>" >> $env:GITHUB_STEP_SUMMARY
        # And write better log message.
        Write-Output "::error::$filename#L$linenumber - called GitHub Action does not match expected Ref '$ExpectedRef'."

        # Beware the backtick character is the powershell escape character.
        "``````yaml" >> $env:GITHUB_STEP_SUMMARY
        "$title" >> $env:GITHUB_STEP_SUMMARY
        "``````" >> $env:GITHUB_STEP_SUMMARY
    }

    Write-Output "::error::Check Job Summary for more details on which GitHub Actions Refs do not match '$ExpectedRef'."
    exit 1
}
