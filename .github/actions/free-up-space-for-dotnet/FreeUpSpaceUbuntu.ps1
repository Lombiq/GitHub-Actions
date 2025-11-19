$initialSpace = (df / |
        Select-Object -Skip 1 |
        ForEach-Object { $PSItem.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)[3] } |
        Measure-Object -Sum).Sum

df --human-readable

# Remove the local cache of downloaded packages but don't remove installed software.
apt-get clean

# Remove Android SDK.
Remove-Item -Recurse -Force /usr/local/lib/android

# We can't remove all unused Docker images since that would also remove the Elasticsearch image (used in the Set up
# Elasticsearch step) and any possible Docker images from prepared runner images.
# docker image prune --all --force

# We can't remove the unused build cache since that would also remove the Elasticsearch build cache (used in the Set up
# Elasticsearch step) and any possible caches from prepared runner images.
# docker builder prune --all --force

# Remove Java (JDKs).
Remove-Item -Recurse -Force /usr/lib/jvm

# Remove Swift toolchain.
Remove-Item -Recurse -Force /usr/share/swift

# Remove Haskell (GHC).
Remove-Item -Recurse -Force /opt/ghc
Remove-Item -Recurse -Force /usr/local/.ghcup

# Remove Julia.
Remove-Item -Recurse -Force /usr/local/julia*

df --human-readable

$finalSpace = (df / |
        Select-Object -Skip 1 |
        ForEach-Object { $PSItem.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)[3] } |
        Measure-Object -Sum).Sum
$freedSpace = [math]::Round(($finalSpace - $initialSpace) / 1024 / 1024, 2)
Write-Output "Freed up approximately $freedSpace GB of storage space."
