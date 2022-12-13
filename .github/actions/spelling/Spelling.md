# Spell checking

## Basics

Since this action is an extension of the [check-spelling](https://github.com/check-spelling/check-spelling) action, familiriaze yourself with its concepts and configuration options, especially about [dictionary files](https://github.com/check-spelling/check-spelling).
One important concept is that the spell checking process replaces matched words with a space character and built-in dictionaries are checked first.

## Guidelines for adding new dictionary entries

These help you decide if you should, and if yes, in what way add new entries to the configuration files, such as `allow.txt`, `expect.txt`, `patterns.txt`, etc.

1. When confronted with unrecognized words in a spell checking report, consider which of those are actually words that make sense to type, instead of just being remainders (because some parts of it were replaced with a space character due to matching an earlier dictionary entry) of another word or a technical string.
