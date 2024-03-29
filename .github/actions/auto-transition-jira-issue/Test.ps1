# You can use this script to test Set-JiraIssueStatus locally, after filling out the credentials below. Be sure not to
# commmit those!
$Env:JIRA_BASE_URL = 'https://lombiq.atlassian.net'
$Env:JIRA_USER_EMAIL = 'your.name@lombiq.com'
$Env:JIRA_API_TOKEN = 'your API token here'

# Add the Script directory to the PATH (just for the duration of this script) so that scripts from there will be
# available without specifying the full path.
$currentScriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$relativeFolderPath = Join-Path -Path $currentScriptDirectory -ChildPath '..\..\..\Scripts'
$Env:Path += ";$relativeFolderPath"

# If you don't have the GitHub CLI installed, then you'll also need to set the $issueKey variable by hand in the script.
$issueParams = @{
    Repository = 'Lombiq/GitHub-Actions'
    PullRequestNumber = 328
    IsDone = $true
    IsResolve = $false
}

.\Set-JiraIssueStatus.ps1 @issueParams
