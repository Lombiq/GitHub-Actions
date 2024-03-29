[Diagnostics.CodeAnalysis.SuppressMessage(
    'PSAvoidUsingConvertToSecureStringWithPlainText',
    '',
    # Also see: https://github.com/PowerShell/PSScriptAnalyzer/issues/574.
    Justification = 'The API token already comes from a secure store. Under GHA, we can''t make it any more secure.')]
param (
    [string]$ApiEndpoint,
    [string]$Method,
    [string]$BodyJson
)

$secureApiKey = ConvertTo-SecureString -String $Env:JIRA_API_TOKEN -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Env:JIRA_USER_EMAIL, $secureApiKey

$parameters = @{
    Uri = "$($Env:JIRA_BASE_URL.TrimEnd('/'))/rest/api/2/$ApiEndpoint"
    Method = $Method
    ContentType = 'application/json'
    Headers = @{
        'Accept' = 'application/json'
    }
    Authentication = 'Basic'
    Credential = $credential
}

if ($BodyJson)
{
    $parameters['Body'] = $BodyJson
}

Invoke-RestMethod @parameters
