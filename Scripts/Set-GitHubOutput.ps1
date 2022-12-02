param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]
    $Key,

    # Not mandatory so it can be intentionally an empty string.
    [Parameter(Mandatory = $false, Position = 1)]
    [string]
    $Value
)

"$Key=$Value" >> $Env:GITHUB_OUTPUT
