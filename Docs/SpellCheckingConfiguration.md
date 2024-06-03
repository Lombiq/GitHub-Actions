# Spell-checking configuration advice

## Introduction

Since our spell-checking [action](../.github/actions/spelling/action.yml) and [workflow](../.github/workflows/spelling.yml) are an extension of [check-spelling](https://github.com/check-spelling/check-spelling), make sure that you familiarize yourself with its concepts and configuration options first.

When integrating spell-checking to your project for the first time or working on resolving a greater number of unrecognized entries, take small, incremental steps and don't rush adding everything to a dictionary file. Some entries can signal that certain file types or specific files should be excluded and in some cases a useful ignore pattern can emerge too.

## General tips

- You can reduce your spell-checking configuration by excluding submodules that are spell-checked on their own or as part of a larger parent project. The best examples are [OrchardCore.Commerce](https://github.com/OrchardCMS/OrchardCore.Commerce) and having a submodule that is also a submodule of [Open Source Orchard Core Extensions (OSOCE)](https://github.com/Lombiq/Open-Source-Orchard-Core-Extensions): Submitting a pull request in such a submodule requires you to open a parent PR in OSOCE to make sure that spell-checking is executed on the updated code before it gets merged.
- The spell-checking process replaces matched words with a space character and built-in configuration files are checked first.
- The order of entries within a configuration file matters.
- Regex patterns are only processed per-line, i.e., they can only affect a single line at a time.

## Configuration files

[Configuration files](https://github.com/check-spelling/check-spelling/wiki/Configuration#files) allow you to define words and patterns that shouldn't be considered spelling mistakes, e.g.:

- _allow.txt_: Normal, expected words that just simply weren't added to the base or other referenced dictionary files yet.
- _excludes.txt_: Perl-style regexes to ignore specific paths, files or extensions.
- _expect.txt_: Dictionary file of arbitrary strings that aren't words, but otherwise valid and aren't spelling mistakes.
- _patterns.txt_: Technical strings that aren't made up of words or word stems but follow a certain structure or pattern can be skipped using Perl-styled regexes. Some technical strings are already covered in Lombiq's version, such as hex color codes, Git commit hashes, GUIDs, and more.

You can provide these files in your own repository and by default they must be placed under the path _.github/actions/spelling_ (configurable through the action/workflow). To ease maintaining dictionary files (and keep a consistent behavior), keep the entries sorted alphabetically.

## Tips for external dictionaries

When the spell-checking process finishes with errors detected, the report commented automatically to the PR will give recommendations for external dictionaries that cover some of the unrecognized entries. These dictionaries can be added to your action/workflow configuration so they are included during spell-checking. Even if a dictionary covers a lot of unrecognized entries, it might not be suitable for your project and could leave you with a lot of false negative detections.

- Before adding a dictionary, check if it's contextually relevant. For example, the Typescript dictionary seems to appear frequently in the recommendations for ASP.NET Core-based projects having mostly C# code, so be cautious if your project doesn't actually utilise that technology.
- Only add one dictionary at a time so that recommendations are re-evaluated correctly. This makes it easier to keep your configuration at the necessary minimum, since some dictionaries are overlapping.
- Also check if the contents of the dictionary make sense. Some recommended libraries seem to have a great number of entries that seem useless in light of how the spell-checking process works now. That is likely due to those dictionary files being outdated and fundamental changes have been made to process since.
- Try to avoid large dictionaries, like the one for C++: It has over 30 thousand entries, because it casts a net way too large and contains a ton of entries that should have been excluded by other means (e.g., a pattern, ignoring a line or a whole file).

## When not to add entries to dictionary files

Before adding an entry to one of the dictionary files, consider the following:

- The order of entries in the spelling dictionary prefixes parameter in your workflow call matters, so the most specific ones, like your own should come before more generic ones, like "cspell".
- When confronted with unrecognized words in a spell-checking report, consider which of those are actually words that make sense to type, instead of just being remainders (because some parts of the original text were replaced with a space character due to matching an earlier entry) of another word or a technical string.
- Also look at the execution log to see where the unrecognized entry is coming from to find out what the original text was in the code. The additional context can help determining how to handle it.
- Rare cases that we don't expect to show up overall more than 3 times and strings that are valid in a single situation should generally be ignored in-place without adding them to a dictionary file. Placing the `#spell-check-ignore-line` string somewhere in a line (for example in a comment at the end of a line of code) will exclude that line completely from spell-checking. In Markdown, add an HTML comment at the end of the line: `<!-- #spell-check-ignore-line -->`.

## Helper scripts for local development

When using custom dictionary files on top of external ones (such as the ones from [check-spelling](https://github.com/check-spelling/cspell-dicts/tree/master) or [Lombiq's](../.github/actions/spelling)), these scripts can help reducing the number of entries you need to add to your own:

- _Merge-SpellCheckingDictionaryFile.ps1_: Use this to maintain your _excludes.txt_ file by adding the entries from another file, while still keeping your own. To just remove duplicates and sort the entries alphabetically in a single configuration file, pass in the same file for both parameters.
- _Optimize-SpellCheckingDictionaryFile.ps1_: Use this to remove entries from your dictionary files that are already present in an external one you're referencing.

## Working with a non-dev branch of `Lombiq.GitHub.Actions`

When working on functional changes, updating dictionaries or the configuration of the spelling action/workflow, the following branch references (from `dev` to the new branch) have to be updated to be able correctly test the changes in a consumer project:

- If the consumer project doesn't have any configuration files on its own, change the default value of the `default-configuration-repository` parameter in the spelling workflow (or the action if you're using that directly) or override its value in the consumer workflow.
- In the `uses` parameter of every step in the spelling and spelling-this-repo workflows that call an action in `Lombiq.GitHub.Actions`.
- In the URL of the lombiq-lgha prefix in the "Merge dictionary source prefixes" step of the spelling action.
