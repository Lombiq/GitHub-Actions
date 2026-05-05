param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]
    $Key,

    # Not mandatory so it can be intentionally an empty string.
    [Parameter(Mandatory = $false, Position = 1)]
    [string]
    $Value
)

if ($Value -match "`n")
{
    # Multi-line values require the heredoc syntax in GITHUB_OUTPUT.
    $delimiter = [System.Guid]::NewGuid().ToString()
    "$Key<<$delimiter`n$Value`n$delimiter" >> $Env:GITHUB_OUTPUT
}
else
{
    "$Key=$Value" >> $Env:GITHUB_OUTPUT
}
