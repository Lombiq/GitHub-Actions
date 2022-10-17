param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Title
)

return $Title -match '^\s*\w+-\d+\s*:'
