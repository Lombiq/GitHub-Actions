param(
    [parameter(Mandatory = $true)][string]$ApplicationInsightsResourceId,
    [parameter(Mandatory = $true)][string]$ReleaseName,
    [parameter(Mandatory = $false)][string]$Timestamp = '',
    [parameter(Mandatory = $false)]$ReleaseProperties = @()
)

Write-Output "Adding release annotation with the release name `"$ReleaseName`"."

$annotation = @{
    Id = [Guid]::NewGuid()
    AnnotationName = $ReleaseName
    EventTime = if ($Timestamp) { $Timestamp } else { (Get-Date).ToUniversalTime().GetDateTimeFormats('s')[0] }
    # AI only displays annotations from the "Deployment" category so this must be this string.
    Category = 'Deployment'
    Properties = ConvertTo-Json $ReleaseProperties -Compress
}

# Encoding parenthesis to prevent the request from failing.
$ApplicationInsightsResourceId = $ApplicationInsightsResourceId.Replace('(', '%28').Replace(')', '%29')

# Double escaping is not needed anymore, for more info see: https://github.com/Azure/azure-cli/issues/15529#issuecomment-1211884315
$body = ConvertTo-Json $annotation -Compress

# Az CLI and Invoke-AzRestMethod both work in GitHub Actions, but Az throws various (inconsistent) errors in localhost.
Invoke-AzRestMethod -Path "$ApplicationInsightsResourceId/Annotations?api-version=2015-05-01" -Method PUT -Payload $body

if (-not $?)
{
    exit 1
}
