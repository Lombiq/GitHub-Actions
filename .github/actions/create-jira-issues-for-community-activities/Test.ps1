$Env:JIRA_BASE_URL = 'https://lombiq.atlassian.net'
$Env:JIRA_USER_EMAIL = 'your.name@lombiq.com'
$Env:JIRA_API_TOKEN = 'your API token here'
$Env:JIRA_PROJECT_KEY = 'ADHOC'

# Add the Script directory to the PATH (just for the duration of this script) so that scripts from there will be
# available without specifying the full path.
$currentScriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$relativeFolderPath = Join-Path -Path $currentScriptDirectory -ChildPath '..\..\..\Scripts'
$Env:Path += ";$relativeFolderPath"

$issueParams = @{
    Summary = 'Test issue'
    Description = 'This is a test issue'
    Type = 'Task'
    IssueComponent = 'Test'
    LinkUrl = 'https://lombiq.com'
    LinkTitle = 'Lombiq'
}

.\Add-JiraIssue.ps1 @issueParams
