# Read both files.
$setupCfgPath = 'setup.cfg'
$codespellRcPath = '.codespellrc'

if (-not (Test-Path $setupCfgPath))
{
    Write-Error "The $setupCfgPath file was not found in the current directory."
    exit 1
}

if (-not (Test-Path $codespellRcPath))
{
    Write-Output "A $codespellRcPath file was not found in the current directory. No configuration values will be merged."
    exit
}

# Extract content from the files.
$setupCfgContent = Get-Content $setupCfgPath -Raw
$codespellRcContent = Get-Content $codespellRcPath -Raw

# Extract the lines with += from .codespellrc.
$plusAssignPattern = '([a-zA-Z0-9\-_]+)\s*\+=\s*(.+)'
$concatenatingLineMatches = [regex]::Matches($codespellRcContent, $plusAssignPattern)

foreach ($concatenatingLineMatch in $concatenatingLineMatches)
{
    $key = $concatenatingLineMatch.Groups[1].Value
    $valuesToAdd = $concatenatingLineMatch.Groups[2].Value.Trim()

    # Find the corresponding key in setup.cfg.
    $regexSetupKey = "($key\s*=\s*)(.+)"
    $setupMatch = [regex]::Match($setupCfgContent, $regexSetupKey)

    if ($setupMatch.Success)
    {
        $existingValues = $setupMatch.Groups[2].Value.Trim()

        # Concatenate the two values as strings.
        $concatenatedValues = "$existingValues$valuesToAdd"

        # Replace the key's value in setup.cfg.
        $setupCfgContent = $setupCfgContent -replace $regexSetupKey, "`$1$concatenatedValues"
    }
    else
    {
        $message = "Key ""$key"" not found in the default setup.cfg. You can't concatenate values for a key that "
        $message += 'doesn''t exist. To add new configuration, use ""="" instead of ""+="". If you are sure the default '
        $message += 'setup.cfg contains a matching key, check your spelling.'

        Write-Error $message

        exit 1
    }
}

# Save the updated setup.cfg.
Set-Content $setupCfgPath -Value $setupCfgContent

Write-Output "The $setupCfgPath file has been updated successfully."
