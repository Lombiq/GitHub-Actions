const textLintConfig = {
    plugins: {},
    filters: {
        comments: true,
    },
    rules: {
        'common-misspellings': true,
        // Text files are usually edited with word wrap, no need to enforce line length.
        'line-length': false,
        'max-comma': true,
        'no-empty-section': true,
        'no-todo': true,
        'no-zero-width-spaces': true,
        'no-start-duplicated-conjunction': true,
        // This rule generates a lot of false positives on Windows. False negatives are avoided by linting on Linux too.
        'doubled-spaces': process.platform !== 'win32',
    },
};

module.exports = textLintConfig;
