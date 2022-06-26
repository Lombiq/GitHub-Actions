<#
.Synopsis
Fails the current step with the provided message. Same as "core.setFailed()" from the official toolkit
(https://github.com/actions/toolkit).
#>
function Set-Failed([Parameter(Mandatory = $True)] [string] $Message)
{
    Write-Output "::error::$Message"
    exit 1
}