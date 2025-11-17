$initialSpace = (df / |
    Select-Object -Skip 1 |
    ForEach-Object { $PSItem.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)[3] } |
    Select-Object -First 1)

df -h

# Remove the local cache of downloaded packages but don't remove installed software.
sudo apt-get clean

# Remove Android SDK.
sudo rm -rf /usr/local/lib/android

# Remove all unused Docker images.
sudo docker image prune --all --force

# Remove unused build cache.
sudo docker builder prune --all --force

# Remove Java (JDKs).
sudo rm -rf /usr/lib/jvm

# Remove Swift toolchain.
sudo rm -rf /usr/share/swift

# Remove Haskell (GHC).
sudo rm -rf /opt/ghc
sudo rm -rf /usr/local/.ghcup

# Remove Julia.
sudo rm -rf /usr/local/julia*

$finalSpace = (df / |
    Select-Object -Skip 1 |
    ForEach-Object { $PSItem.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)[3] } |
    Select-Object -First 1)
$freedSpace = [math]::Round(($finalSpace - $initialSpace) / 1GB, 2)
Write-Output "Freed up approximately $freedSpace GB of disk space."

df -h
