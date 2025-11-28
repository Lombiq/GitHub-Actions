const textLintConfig = {
    plugins: {},
    filters: {
        comments: true,
    },
    rules: {
        'common-misspellings': true,
        'max-comma': true,
        'no-empty-section': true,
        'no-todo': true,
        'no-zero-width-spaces': true,
        'no-start-duplicated-conjunction': true,
    },
};

module.exports = textLintConfig;
