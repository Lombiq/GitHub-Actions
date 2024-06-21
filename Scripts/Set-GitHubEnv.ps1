param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]
    $Key,

    # Not mandatory so it can be intentionally an empty string.
    [Parameter(Mandatory = $false, Position = 1)]
    [string]
    $Value
)

# This ceremony is needed to make the env vars available in subsequent steps too, see:
# https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-environment-variable.
# Note that in PowerShell, echo is not needed. Make sure not to put spaces around the equal signs when writing to
# $Env:GITHUB_ENV.
"$Key=$Value" >> $Env:GITHUB_ENV
Set-Item env:$Key -Value $Value
