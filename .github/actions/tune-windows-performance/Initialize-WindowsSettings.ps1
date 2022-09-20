# Taken from https://gist.github.com/xnohat/0359165197b5f690b438c96861e8041a.

# Disable 8dot3 filenames.
fsutil behavior set disable8dot3 1

# Increase NTFS MFT zone size.
fsutil behavior set mftzone 2

# Disable last access time on all files.
fsutil behavior set disablelastaccess 1

# Changing disable8dot3 and mftzone needs a reboot.
Restart-Computer -Force
