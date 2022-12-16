# Spell checking

## Basics

Since this action is an extension of [check-spelling](https://github.com/check-spelling/check-spelling), familiarize yourself with its concepts and configuration options first.

One important concept is that the spell checking process replaces matched words with a space character and built-in dictionaries are checked first. The order of entries within a dictionary file also matters.

## Dictionary files

[Dictionary files](https://github.com/check-spelling/check-spelling/wiki/Configuration#files) allow you to define strings that shouldn't be considered spelling mistakes, e.g.:

- _allow.txt_: Normal, expected words that just simply weren't added to the base dictionary yet.
- _excludes.txt_: File names and extensions to be ignored.
- _expect.txt_: Arbitrary strings that aren't words, but otherwise valid and aren't spelling mistakes.
- _patterns.txt_: Perl-style regexes for more flexibility.

You can provide these files in your own repository, but they must be placed under the path _.github/actions/spelling_.

## Guidelines for adding new dictionary entries

Before adding an entry to one of the dictionary files, consider the following:

1. When confronted with unrecognized words in a spell checking report, consider which of those are actually words that make sense to type, instead of just being remainders (because some parts of the original text were replaced with a space character due to matching an earlier dictionary entry) of another word or a technical string.
2. Technical strings that aren't made up of words or word stems but follow a certain structure or pattern can be allowed with a regex in _patterns.txt_. Some technical strings are already covered, such as hex color codes, Git commit hashes, GUIDs, and more.
3. Rare cases that we don't expect to show up overall more than 3 times and special cases that are valid in one place, but would otherwise be a typo should be ignored in-place without adding them to the dictionary. Placing the `#spell-check-ignore-line` string somewhere in a line (for example in a comment at the end of a line of code) will exclude that line completely from spell checking.
