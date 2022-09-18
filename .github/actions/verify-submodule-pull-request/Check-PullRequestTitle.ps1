# Note that this script is also used from create-jira-issues-for-community-activities.
param([string] $Title)

return $Title -match '^\s*\w+-\d+\s*:'
