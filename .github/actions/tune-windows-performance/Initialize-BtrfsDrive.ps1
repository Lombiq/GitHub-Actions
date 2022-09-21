# Since Hyper-V is not enabled deliberately (https://github.com/actions/runner-images/pull/2525) and can't be enabled
# without a reboot, which is not possible on GitHub Actions runners, we can't use New-VHD and Mount-VHD. Thus, resorting
# to diskpart. For the same reason, we can't mount ext4 drives from WSL2. The only option for a non-Windows filesystem
# is thus Btrfs with WinBtrfs. See: https://github.com/Lombiq/GitHub-Actions/issues/32.

# Since the working-directory is configured as wd, we need to go up one directory to create it.
cd ..

$vhdxPath = Join-Path $Env:GITHUB_WORKSPACE Workspace.vhdx

choco install winbtrfs

# Diskpart uses an interactive mode. We thus use /s to feed a script to it.
# You get 14 GB of storage space on GitHub-hosted runners, so erring on the safe side with 13 GB max size, see:
# https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources

# mkbtrfs needs a drive letter to format, but we can't mount the drive until it's formatted, and diskpart can't format
# with btrfs... So, formatting with NTFS first.

@"
create vdisk file='$vhdxPath' maximum=13312 type=expandable
select vdisk file='$vhdxPath'
attach vdisk
clean
create partition primary
format fs=ntfs
assign letter=Q
"@ > DiskpartCommands.txt

diskpart /s DiskpartCommands.txt

# This will change the drive letter to the next available one.
Write-Output "Starting Btrfs formatting."
mkbtrfs Q: BtrfsDrive
Write-Output "Finished Btrfs formatting."

# For some reason, the drive is not immediately available once the above finishes.
$i = 0;
while ($i -lt 10 -and (Get-Volume | Where-Object {$_.FileSystemLabel -eq "BtrfsDrive"}).Length -eq 0)
{
    Start-Sleep -Seconds 1
}

$driveLetter = (Get-Volume -FileSystemLabel "BtrfsDrive").DriveLetter
# Short folder name not to have Windows long path issues. "wd" as in working directory.
New-Item -Path "wd" -ItemType SymbolicLink -Value "$($driveLetter):\\"
