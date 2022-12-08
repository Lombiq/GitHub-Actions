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
    # AI only displays annotations from the "Deployment" category so this must be this string.
    Category = "Deployment";
    Properties = ConvertTo-Json $ReleaseProperties -Compress
}

$params = @{
    Path = "$ApplicationInsightsResourceId/Annotations?api-version=2015-05-01" 
    Method = 'PUT'
    Payload = (ConvertTo-Json $annotation -Compress) -replace '(\\+)"', '$1$1"' -replace "`"", "`"`""
}

$response = Invoke-AzRestMethod @params

if ($response.StatusCode -ne 200)
{
    Write-Output $response
    Write-Error "Adding the release annotation failed with the status code $($response.StatusCode) and the above response."
}
