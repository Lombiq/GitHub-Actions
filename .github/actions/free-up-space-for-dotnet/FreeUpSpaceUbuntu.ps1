$rootDrive = (Get-PSDrive /)[0]
$initialSpace = $rootDrive.Free

df --human-readable

# Remove the local cache of downloaded packages but don't remove installed software.
sudo apt-get clean

# Remove Android SDK.
sudo Remove-Item -Recurse -Force /usr/local/lib/android

# We can't remove all unused Docker images since that would also remove the Elasticsearch image (used in the Set up
# Elasticsearch step) and any possible Docker images from prepared runner images.
# sudo docker image prune --all --force

# We can't remove the unused build cache since that would also remove the Elasticsearch build cache (used in the Set up
# Elasticsearch step) and any possible caches from prepared runner images.
# sudo docker builder prune --all --force

# Remove Java (JDKs).
sudo Remove-Item -Recurse -Force /usr/lib/jvm

# Remove Swift toolchain.
sudo Remove-Item -Recurse -Force /usr/share/swift

# Remove Haskell (GHC).
sudo Remove-Item -Recurse -Force /opt/ghc
sudo Remove-Item -Recurse -Force /usr/local/.ghcup

# Remove Julia.
sudo Remove-Item -Recurse -Force /usr/local/julia*

df --human-readable

$finalSpace = $rootDrive.Free
$freedSpace = [math]::Round(($finalSpace - $initialSpace) / 1GB, 2)
Write-Output "Freed up approximately $freedSpace GB of storage space."
