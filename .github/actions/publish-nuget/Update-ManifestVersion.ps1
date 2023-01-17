param(
    [string]
    $WorkDir,
    [string]
    $PackageVersion
)

$manifests = Get-ChildItem $WorkDir -File -Recurse -Filter 'Manifest.cs' |
    Select-String -List -Pattern '(OrchardCore.Modules.Manifest|OrchardCore.DisplayManagement.Manifest)' |
    Select-Object -ExpandProperty Path

foreach ($manifest in $manifests)
{
    $regex = '(?<head>\[assembly:\s*(Module|Theme)\(([^\]]*Version\W*=\W*"))([^"]*)', "`${head}$PackageVersion"
    (Get-Content -Raw $manifest) -replace $regex | Out-File $manifest

    Write-Output "Version updated in $manifest to $PackageVersion"
}
