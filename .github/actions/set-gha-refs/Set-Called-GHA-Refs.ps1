param(
    [String[]] $CalledRepoBaseIncludeList,
    [String[]] $PathIncludeList,
    [String[]] $FileIncludeList,
    [String] $ExpectedRef
)

if ($CalledRepoBaseIncludeList.Count -eq 0)
{
    Write-Output '::warning file=Check-Called-GHA-refs.ps1,line10::CalledRepoBaseIncludeList is empty which is unexpected. If this was intentional, you can ignore this warning.'
}
else
{
    $CalledRepoBaseIncludeList = $CalledRepoBaseIncludeList.ForEach({ 'uses:\s*' + $PSItem + '(.*)@(.*)' })

    $matchedRefs = Get-ChildItem -Path $PathIncludeList -Include $FileIncludeList -Force -Recurse |
        Select-String -Pattern $CalledRepoBaseIncludeList

    if ($matchedRefs.Count -gt 0)
    {
        foreach ($matched in $matchedRefs)
        {
            $oldline = $matched.Line
            $newline = $matched.Line -Replace '@(.*)', "@$ExpectedRef"

            if ($oldine -ne $newline)
            {
                Write-Output "$oldline => $newline"

                $filename = $matched.RelativePath($pwd)
                $linenumber = $mismatch.LineNumber
                $title = "GHA Ref pinned to '$ExpectedRef'"

                (Get-Content $filename).Replace($oldline, $newline) | Set-Content $filename

                Write-Output "::notice file=$filename,line=$linenumber,title=$title::GHA Ref changed to '$ExpectedRef'"
            }
        }
    }
}
