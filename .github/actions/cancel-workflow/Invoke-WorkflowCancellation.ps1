param ($Repository, $RunId)

Write-Output "::error::Canceling workflow due to one of the jobs failing."
$url = "https://api.github.com/repos/$Repository/actions/runs/$RunId/cancel"
$headers = @{"Authorization" = "Bearer $($Env:GITHUB_TOKEN)"; "Accept" = "application/vnd.github+json"}
Invoke-WebRequest $url -Headers $headers -Method Post
