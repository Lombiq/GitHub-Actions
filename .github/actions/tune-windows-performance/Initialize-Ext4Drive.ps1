Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

New-VHD -Path (Join-Path $Env:GITHUB_WORKSPACE Workspace.vhdx) -Dynamic -SizeBytes 10GB
