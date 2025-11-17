$initialSpace = (df / |
        Select-Object -Skip 1 |
        ForEach-Object { $PSItem.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)[3] } |
        Measure-Object -Sum).Sum

df --human-readable

# Remove the local cache of downloaded packages but don't remove installed software.
sudo apt-get clean

# Remove Android SDK.
sudo rm -rf /usr/local/lib/android

# We can't remove all unused Docker images since that would also remove the Elasticsearch image (used in the Set up
# Elasticsearch step) and any possible Docker images from prepared runner images.
# sudo docker image prune --all --force

# We can't remove the unused build cache since that would also remove the Elasticsearch build cache (used in the Set up
# Elasticsearch step) and any possible caches from prepared runner images.
# sudo docker builder prune --all --force

# Remove Java (JDKs).
sudo rm -rf /usr/lib/jvm

# Remove Swift toolchain.
sudo rm -rf /usr/share/swift

# Remove Haskell (GHC).
sudo rm -rf /opt/ghc
sudo rm -rf /usr/local/.ghcup

# Remove Julia.
sudo rm -rf /usr/local/julia*

df --human-readable

$finalSpace = (df / |
        Select-Object -Skip 1 |
        ForEach-Object { $PSItem.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)[3] } |
        Measure-Object -Sum).Sum
$freedSpace = [math]::Round(($finalSpace - $initialSpace) / 1024 / 1024, 2)
Write-Output "Freed up approximately $freedSpace GB of storage space."
