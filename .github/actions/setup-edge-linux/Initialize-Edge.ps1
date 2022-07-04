# Issue for tool request: https://github.com/actions/virtual-environments/issues/5845.

param(
    [string]
    $EdgeVersion
)

bash -c @"
curl -O https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_${EdgeVersion}_amd64.deb
sudo apt install microsoft-edge-stable_${EdgeVersion}_amd64.deb
"@

Write-Output "/opt/microsoft/msedge" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
