param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]
    $Key,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]
    $Value
)

Write-Output "Output: $Key=$Value"
"$Key=$Value" >> $Env:GITHUB_OUTPUT
