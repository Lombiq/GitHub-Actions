import fs from 'node:fs';

// eslint-disable n/no-sync -- This script would not benefit from async.
export default {
    ignores: fs
        .readFileSync('.markdownlintignore', 'utf8')
        .split('\n')
        .map((line) => line.split('#')[0].trim())
        .filter((line) => line.length),
    config:
    {
        default: true,
        MD004: { style: 'dash' },
        MD013: false,
        MD028: false,
        MD033: { allowed_elements: ['kbd'] },
        MD049: { style: 'underscore' },
        MD050: { style: 'asterisk' },
        MD059: false,
    },
};
