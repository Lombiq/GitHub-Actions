# Since Hyper-V is not enabled deliberately (https://github.com/actions/runner-images/pull/2525) and can't be enabled
# without a reboot, which is not possible on GitHub Actions runners, we can't use New-VHD and Mount-VHD. Thus, resorting
# to diskpart.

# Diskpart uses an interactive mode. We thus use /s to feed a script to it.
$vhdxPath = Join-Path $Env:GITHUB_WORKSPACE Workspace.vhdx

@"
create vdisk file='$vhdxPath' maximum=10240 type=expandable
select vdisk file='$vhdxPath'
attach vdisk
"@ > DiskpartCommands.txt

diskpart /s DiskpartCommands.txt
