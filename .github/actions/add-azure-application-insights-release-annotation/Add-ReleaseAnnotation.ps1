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
$ApplicationInsightsResourceId = $ApplicationInsightsResourceId.Replace('(', '%28').Replace(')', '%29')

# Double escaping is not needed anymore, for more info see: https://github.com/Azure/azure-cli/issues/15529#issuecomment-1211884315
$body = ConvertTo-Json $annotation -Compress

az rest --method put --uri "$($ApplicationInsightsResourceId)/Annotations?api-version=2015-05-01" --body "$($body) "


if (!$?)
{
    exit 1
}
