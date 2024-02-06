param(
    [parameter(Mandatory = $true)][string]$ApplicationInsightsResourceId,
    [parameter(Mandatory = $true)][string]$ReleaseName,
    [parameter(Mandatory = $false)]$ReleaseProperties = @()
)

Write-Output "Adding release annotation with the release name `"$ReleaseName`"."

$annotation = @{
    Id = [GUID]::NewGuid();
    AnnotationName = $ReleaseName;
    EventTime = (Get-Date).ToUniversalTime().GetDateTimeFormats("s")[0];
    Category = "Deployment"; #Application Insights only displays annotations from the "Deployment" Category
    Properties = ConvertTo-Json $ReleaseProperties -Compress
}

# Encoding parenthesis to prevent the request from failing.
#$ApplicationInsightsResourceId = $ApplicationInsightsResourceId.Replace('(', '%28').Replace(')', '%29')
$body = (ConvertTo-Json $annotation -Compress) -replace '(\\+)"', '$1$1"' -replace "`"", "`"`""

az rest --method put --uri "$($ApplicationInsightsResourceId)/Annotations?api-version=2015-05-01" --body "$($body) " --debug

az rest --method put --uri "$($ApplicationInsightsResourceId)/Annotations?api-version=2015-05-01" --body "$($body) " --headers "Content-Type=application/json" --debug

az rest --method put --uri "$($ApplicationInsightsResourceId)/Annotations?api-version=2015-05-01" --body "$($body)" --headers "Content-Type=application/json" --debug

az rest --method put --uri "$($ApplicationInsightsResourceId)/Annotations?api-version=2015-05-01" --body "$($body)" --debug

if (!$?)
{
    exit 1
}