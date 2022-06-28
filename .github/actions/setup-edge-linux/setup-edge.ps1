function Program {
    param(
        [string]
        $EdgeVersion
    )

    bash -c "curl -O https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_${EdgeVersion}_amd64.deb"
    bash -c "sudo apt install ./microsoft-edge-stable_${EdgeVersion}_amd64.deb"

    echo "/opt/microsoft/msedge" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
}

Program $args[0]
