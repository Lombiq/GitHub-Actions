param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]
    $Key,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]
    $Value
)

"$Key=$Value" >> $Env:GITHUB_OUTPUT
