function Program {
    param(
        [string]
        $EdgeLinuxVersion,
        [string]
        $EdgeWindowsVersion
    )

    if ($Env:RUNNER_OS -eq "Windows")
    {
        choco install microsoft-edge --version $EdgeWindowsVersion -y
    }
    else
    {
        bash -c "curl -O https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_$EdgeLinuxVersion_amd64.deb"
        bash -c "sudo apt install ./microsoft-edge-stable_$EdgeLinuxVersion_amd64.deb"
    }
}

Program $args[0] $args[1]
