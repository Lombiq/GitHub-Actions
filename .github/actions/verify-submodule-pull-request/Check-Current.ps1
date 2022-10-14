param([string] $Title)

if (Confirm-PullRequestTitle $Title) { exit 0 }
Set-Failed ('The pull request title is not in the expected format. Please start with the issue code followed by a ' +
    'colon and the title, e.g. "PROJ-123: My PR Title".')
