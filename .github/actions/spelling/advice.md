# Spell-checking configuration advice

What to do with false positives that aren't actually spelling mistakes? If the word is only used in a few cases, add the `#spell-check-ignore-line` comment to ignore the whole line. For a more common occurrence, add it to the appropriate dictionary file or define a pattern that matches it and similar cases.

For further details, please read [our recommendations for maintaining the spell-checking configuration](https://github.com/Lombiq/GitHub-Actions/blob/dev/Docs/SpellCheckingConfiguration.md) carefully!
