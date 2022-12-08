<#
.Synopsis
   Generates GitHub output values useful to suffix the names of artifacts to be uploaded.
#>

param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]
    $BuildDirectoryPath
)

$friendlyBuildDirectoryName = $BuildDirectoryPath.Replace('/', '__')
$runnerSuffix = "$Env:RUNNER_OS-$Env:RUNNER_ARCH-$Env:RUNNER_NAME"

Set-GitHubOutput 'friendly-build-directory-name' $friendlyBuildDirectoryName
Set-GitHubOutput 'runner-suffix' $runnerSuffix
Set-GitHubOutput 'artifact-name-suffix' "$friendlyBuildDirectoryName-$runnerSuffix"
Write-Output "artifact-name-suffix: $friendlyBuildDirectoryName-$runnerSuffix"
