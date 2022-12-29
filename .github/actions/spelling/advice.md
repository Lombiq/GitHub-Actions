# Spell checking configuration advices

## Basics

Since this action is an extension of [check-spelling](https://github.com/check-spelling/check-spelling), make sure that you familiarize yourself with its concepts and configuration options first. Some of the most notable ones:

- The spell checking process replaces matched words with a space character and built-in configuration files are checked first.
- The order of entries within a configuration file matters.

## Configuration files

[Configuration files](https://github.com/check-spelling/check-spelling/wiki/Configuration#files) allow you to define words and patterns that shouldn't be considered spelling mistakes, e.g.:

- _allow.txt_: Normal, expected words that just simply weren't added to the base or other referenced dictionary files yet.
- _excludes.txt_: Perl-style regexes to ignore specific paths, files or extensions.
- _expect.txt_: Dictionary file of arbitrary strings that aren't words, but otherwise valid and aren't spelling mistakes.
- _patterns.txt_: Technical strings that aren't made up of words or word stems but follow a certain structure or pattern can be skipped using Perl-styled regexes. Some technical strings are already covered in Lombiq's version, such as hex color codes, Git commit hashes, GUIDs, and more.

You can provide these files in your own repository, but they must be placed under the path _.github/actions/spelling_. To ease maintaining dictionary files (and keep a consistent behavior), keep the entries sorted alphabetically.

## When not to add entries to dictionary files

Before adding an entry to one of the dictionary files, consider the following:

1. When confronted with unrecognized words in a spell checking report, consider which of those are actually words that make sense to type, instead of just being remainders (because some parts of the original text were replaced with a space character due to matching an earlier entry) of another word or a technical string.
2. Rare cases that we don't expect to show up overall more than 3 times and strings that are valid in a single situation should be ignored in-place without adding them to a dictionary file. Placing the `#spell-check-ignore-line` string somewhere in a line (for example in a comment at the end of a line of code) will exclude that line completely from spell checking.

## Helper scripts for local development

When using custom dictionary files on top of external ones (such as the ones from [check-spelling](https://github.com/check-spelling/cspell-dicts/tree/master) or [Lombiq's](https://github.com/Lombiq/GitHub-Actions/tree/dev/.github/actions/spelling)), these scripts can help reducing the number of entries you need to add to your own:

1. _Merge-SpellCheckingDictionaryFile.ps1_: Use this to maintain your _excludes.txt_ file by adding the entries from another file, while still keeping your own. To just remove duplicates and sort the entries alphabetically in a single configuration file, pass in the same file for both parameters.
2. _Optimize-SpellCheckingDictionaryFile.ps1_: Use this to remove entries from your dictionary files that are already present in an external one you're referencing.
