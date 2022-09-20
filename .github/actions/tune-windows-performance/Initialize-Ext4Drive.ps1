# Diskpart uses an interactive mode. We could use /s to feed a script to it but then we'd need to generate the file if
# dynamic data is needed. Doing the below just won't work in PS, piping the stdout to diskpart only works from the CMD.
$vhdxPath = Join-Path $Env:GITHUB_WORKSPACE Workspace.vhdx
cmd.exe /c "(echo create vdisk file='$vhdxPath' maximum=10240 type=expandable) | diskpart"
