<#
.Synopsis
    Removes the entries listed in a dictionary file from another dictionary file.

.DESCRIPTION
    Removes the entries from the target dictionary file that are found in the source dictionary file, then removes
    duplicates and sorts the entries alphabetically.

.EXAMPLE
    Optimize-SpellCheckingDictionaryFile -Source C:\dev\lombiq-allow.txt -Target C:\dev\custom-allow.txt
#>

param(
    [parameter(Mandatory = $true, HelpMessage = 'The path to a dictionary file whose entries you want to remove from ' +
        'another dictionary file.')]
    [string] $Source,

    [parameter(Mandatory = $true, HelpMessage = 'The path to the dictionary files to remove entries from.')]
    [string] $Target
)

$sourceDictionary = Get-Content -Path $Source
$targetDictionary = Get-Content -Path $Target

$targetDictionary = $targetDictionary | Where-Object { $PSItem -notin $sourceDictionary } | Sort-Object -Unique

Set-Content -Path $Target -Value $targetDictionary
