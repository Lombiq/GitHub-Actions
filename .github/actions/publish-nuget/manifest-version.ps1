function Program {
    param(
        [string]
        $WorkDir,
        [string]
        $PackageVersion
    )

    function Update-Manifest-Version {
        param(
            [string]
            $Manifest,
            [string]
            $Version
        )

        (Get-Content -Raw $Manifest) -replace 
            '(?<head>\[assembly:\s*(Module|Theme)\(([^\]]*Version\W*=\W*"))([^"]*)', "`${head}$Version" |
            Out-File $Manifest

         Write-Output "Version updated in $Manifest to $Version"
    }

    $manifests = Get-ChildItem $WorkDir -File -Recurse -Filter "Manifest.cs" |
        Select-String -List -Pattern '(OrchardCore.Modules.Manifest|OrchardCore.DisplayManagement.Manifest)' | 
        Select-Object -ExpandProperty Path

    foreach ($manifest in $manifests) {
        Update-Manifest-Version $manifest $PackageVersion
    }
}

Program $args[0] $args[1]
