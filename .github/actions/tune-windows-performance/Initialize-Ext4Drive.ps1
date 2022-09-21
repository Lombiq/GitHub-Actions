# Since Hyper-V is not enabled deliberately (https://github.com/actions/runner-images/pull/2525) and can't be enabled
# without a reboot, which is not possible on GitHub Actions runners, we can't use New-VHD and Mount-VHD. Thus, resorting
# to diskpart.
# Diskpart uses an interactive mode. We thus use /s to feed a script to it.
$vhdxPath = "D:\Workspace.vhdx"

@"
create vdisk file='$vhdxPath' maximum=10240 type=expandable
select vdisk file='$vhdxPath'
attach vdisk
list disk
"@ > DiskpartCommands.txt

$output = & diskpart /s DiskpartCommands.txt

# For some reason, Split() won't work with the "DiskPart successfully attached the virtual disk file." string, just new
# lines.
$listDiskOutput = $output.Split([Environment]::NewLine)
Write-Output "$($listDiskOutput[3]) KKK"

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

wsl --install
wsl --list --online
wsl --mount "\\.\PhysicalDrive$diskIndex" --bare
