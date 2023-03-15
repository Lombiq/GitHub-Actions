$templates = @{}

if ([string]::IsNullOrEmpty($Env:DISCUSSION_JIRA_ISSUE_DESCRIPTION))
{
    $templates['DISCUSSION_JIRA_ISSUE_DESCRIPTION'] = @'
h1. Summary
See the linked GitHub discussion, including all the comments. Please do all communication there, unless it's confidential or administrative.

h1. Checklist
* Respond to the linked GitHub discussion.
* The "After resolve" section is updated if necessary.

h1. After resolve
Add notes here if anything needs to be done after the issue is resolved, like manual configuration changes. Write in English, suitable to be included in release notes.
'@
}
else
{
    $templates['DISCUSSION_JIRA_ISSUE_DESCRIPTION'] = $Env:DISCUSSION_JIRA_ISSUE_DESCRIPTION
}

if ([string]::IsNullOrEmpty($Env:ISSUE_JIRA_ISSUE_DESCRIPTION))
{
    $templates['ISSUE_JIRA_ISSUE_DESCRIPTION'] = @'
h1. Summary
See the linked GitHub issue, including all the comments. Please do all communication there, unless it's confidential or administrative.

h1. Implementation notes


h1. Checklist
* Assign yourself to the referenced GitHub issue.
* Tests: Determine if necessary.
* The "After resolve" section is updated if necessary.

h1. After resolve
Add notes here if anything needs to be done after the issue is resolved, like manual configuration changes. Write in English, suitable to be included in release notes.
'@
}
else
{
    $templates['ISSUE_JIRA_ISSUE_DESCRIPTION'] = $Env:ISSUE_JIRA_ISSUE_DESCRIPTION
}

if ([string]::IsNullOrEmpty($Env:PULL_REQUEST_JIRA_ISSUE_DESCRIPTION))
{
    $templates['PULL_REQUEST_JIRA_ISSUE_DESCRIPTION'] = @'
h1. Summary
See the linked GitHub pull request, including all the comments. Please do all communication there, unless it's confidential or administrative.

h1. Checklist
* Pull request is reviewed and merged.
* The "After resolve" section is updated if necessary.

h1. After resolve
Add notes here if anything needs to be done after the issue is resolved, like manual configuration changes. Write in English, suitable to be included in release notes.
'@
}
else
{
    $templates['PULL_REQUEST_JIRA_ISSUE_DESCRIPTION'] = $Env:PULL_REQUEST_JIRA_ISSUE_DESCRIPTION
}

return $templates
