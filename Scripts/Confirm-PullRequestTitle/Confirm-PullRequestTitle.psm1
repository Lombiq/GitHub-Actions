function Confirm-PullRequestTitle
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Title
    )

    process
    {
        return $Title -match '^\s*\w+-\d+\s*:'
    }
}
