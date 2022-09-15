# Note that this script is also used from create-jira-issues-for-community-activities.
param([string] $Title)

if ($Title -match '^\s*\w+-\d+\s*:') { exit 0 }
Set-Failed ('The pull request title is not in the expected format. Please start with the issue code followed by a ' +
    'colon and the title, e.g. "PROJ-123: My PR Title".')
