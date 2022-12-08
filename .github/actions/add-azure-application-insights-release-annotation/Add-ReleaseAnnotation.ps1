param(
    [parameter(Mandatory = $true)][string]$ApplicationInsightsResourceId,
    [parameter(Mandatory = $true)][string]$ReleaseName,
    [parameter(Mandatory = $false)]$ReleaseProperties = @()
)

$annotation = @{
    Id = [GUID]::NewGuid();
    AnnotationName = $ReleaseName;
    EventTime = (Get-Date).ToUniversalTime().GetDateTimeFormats("s")[0];
    # AI only displays annotations from the "Deployment" category so this must be this string.
    Category = "Deployment";
    Properties = ConvertTo-Json $ReleaseProperties -Compress
}

$body = (ConvertTo-Json $annotation -Compress) -replace '(\\+)"', '$1$1"' -replace "`"", "`"`""
Invoke-AzRestMethod -Path "$ApplicationInsightsResourceId/Annotations?api-version=2015-05-01" -Method PUT -Payload $body
