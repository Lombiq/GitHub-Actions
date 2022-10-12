param
(
    $DotNetVersion
)

$isExactMatch = !$DotNetVersion.Contains('x')
$requestedVersion = New-Object "System.Version" $DotNetVersion.Replace('x', '0')

if ($isExactMatch)
{
    Write-Output "Checking if the exact version $requestedVersion of the .NET SDK is installed."
}
else
{
    Write-Output "Checking if the minimum version $requestedVersion of the .NET SDK is installed."
}

$sdks = dotnet --list-sdks

foreach ($sdk in $sdks)
{
    $versionPart = $sdk.Split(' ')[0]
    Write-Output $versionPart
    $version = New-Object "System.Version" $versionPart

    if ($isExactMatch -and $requestedVersion -eq $version)
    {
        return $true
    }
    elseif (!$isExactMatch -and $version.Major -eq $requestedVersion.Major -and $version -ge $requestedVersion)
    {
        return $true
    }
}

return $false
