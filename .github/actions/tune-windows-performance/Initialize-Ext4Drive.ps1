# Since Hyper-V is not enabled deliberately (https://github.com/actions/runner-images/pull/2525) and can't be enabled
# without a reboot, which is not possible on GitHub Actions runners, we can't use New-VHD and Mount-VHD. Thus, resorting
# to diskpart. For the same reason, we can't mount ext4 drives from WSL2. The only option for a non-Windows filesystem
# is thus Btrfs with WinBtrfs. See: https://github.com/Lombiq/GitHub-Actions/issues/32.

$vhdxPath = Join-Path $Env:GITHUB_WORKSPACE Workspace.vhdx

# Diskpart uses an interactive mode. We thus use /s to feed a script to it.
@"
create vdisk file='$vhdxPath' maximum=10240 type=expandable
select vdisk file='$vhdxPath'
attach vdisk
list disk
"@ > DiskpartCommands.txt

$output = & diskpart /s DiskpartCommands.txt

Write-Output $output

# For some reason, Split() won't work with the "DiskPart successfully attached the virtual disk file." string, just new
# lines.
$listDiskOutput = $output.Split([Environment]::NewLine)

$lineIndex = 0
foreach ($line in $listDiskOutput)
{
    if ($line.Contains("DiskPart successfully attached the virtual disk file."))
    {
        break
    }

    $lineIndex++
}

# The first 4 lines are empty and the command's output header.
$numberOfDisks = $listDiskOutput.Length - $lineIndex - 4
$diskIndex = $numberOfDisks - 1

wsl --status
wsl --set-default-version 2
wsl --mount "\\.\PhysicalDrive$diskIndex" --bare
