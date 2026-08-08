[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost',
    '',
    Justification = 'These messages github annotations always have to go to the workflow runner virtual console.')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Message,
    [switch] $Warning,
    [switch] $Notice)

$mode = 'error'

if ($Warning) { $mode = 'warning' }
if ($Notice) { $mode = 'notice' }

Write-Host "::$mode::$Message"