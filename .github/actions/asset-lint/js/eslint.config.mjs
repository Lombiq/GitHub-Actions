import fs from 'node:fs';
import path from 'node:path';
import { includeIgnoreFile } from '@eslint/compat';
import js from '@eslint/js';
import { configs, plugins } from 'eslint-config-airbnb-extended';
import { defineConfig } from 'eslint/config';
import globals from 'globals';
import onlyWarn from 'eslint-plugin-only-warn';

const lombiqConfig = defineConfig([{
    name: "Lombiq custom configuration",
    plugins: {
        "only-warn": onlyWarn,
    },

    settings: {
        node: {
            version : ">=24.0.0"
        },
    },

    languageOptions: {
        globals: {
            ...globals.jquery,
            ...globals.browser,
        },

        ecmaVersion: 2020,
        sourceType: "module",

        parserOptions: {
            ecmaVersion: 2020,
            sourceType: "module",
        }
    },

    rules: {
        "max-len": ["warn", 150, 2, {
            ignoreUrls: true,
            ignoreComments: false,
            ignoreRegExpLiterals: false,
            ignoreStrings: false,
            ignoreTemplateLiterals: false,
        }],

        "brace-style": ["warn", "stroustrup", {
            allowSingleLine: true,
        }],

        "prefer-template": "off",

        "no-plusplus": ["warn", {
            allowForLoopAfterthoughts: true,
        }],

        "linebreak-style": "off",

        "no-param-reassign": ["warn", {
            props: false,
        }],

        "wrap-iife": ["warn", "any", {
            functionPrototypeMethods: false,
        }],

        "prefer-arrow-callback": ["warn", {
            allowNamedFunctions: true,
            allowUnboundThis: true,
        }],

        "no-underscore-dangle": ["warn", {
            allowAfterThis: true,
        }],

        "no-restricted-syntax": ["warn", {
            selector: "LabeledStatement",
            message: "Labels are a form of GOTO; using them makes code confusing and hard to maintain and understand.",
        }, {
            selector: "WithStatement",
            message: "`with` is disallowed in strict mode because it makes code impossible to predict and optimize.",
        }],

        "no-unused-expressions": ["warn", {
            allowShortCircuit: true,
            allowTernary: false,
            allowTaggedTemplates: false,
        }],

        "operator-linebreak": ["warn", "after", {
            overrides: {
                "=": "none",
                "?": "ignore",
                ":": "ignore",
            },
        }],

        "no-else-return": ["warn", {
            allowElseIf: true,
        }],

        "object-shorthand": ["warn", "consistent-as-needed"],

        "prefer-destructuring": ["warn", {
            VariableDeclarator: {
                array: false,
                object: false,
            },

            AssignmentExpression: {
                array: true,
                object: false,
            },
        }, {
            enforceForRenamedProperties: false,
        }],

        "indent": ["warn", 4, {
            SwitchCase: 1,
            VariableDeclarator: 1,
            outerIIFEBody: 1,

            FunctionDeclaration: {
                parameters: 1,
                body: 1,
            },

            FunctionExpression: {
                parameters: 1,
                body: 1,
            },

            CallExpression: {
                arguments: 1,
            },

            ArrayExpression: 1,
            ObjectExpression: 1,
            ImportDeclaration: 1,
            flatTernaryExpressions: false,

            ignoredNodes: [
                "JSXElement",
                "JSXElement > *",
                "JSXAttribute",
                "JSXIdentifier",
                "JSXNamespacedName",
                "JSXMemberExpression",
                "JSXSpreadAttribute",
                "JSXExpressionContainer",
                "JSXOpeningElement",
                "JSXClosingElement",
                "JSXFragment",
                "JSXOpeningFragment",
                "JSXClosingFragment",
                "JSXText",
                "JSXEmptyExpression",
                "JSXSpreadChild",
            ],

            ignoreComments: false,
        }],

        "func-names": ["warn", "as-needed"],
        "no-alert": "off",
        "function-paren-newline": ["off", "consistent"],

        "comma-dangle": ["warn", {
            arrays: "always-multiline",
            objects: "always-multiline",
            imports: "always-multiline",
            exports: "always-multiline",
            functions: "never",
        }],

        "function-call-argument-newline": ["warn", "consistent"],
        "strict": ["warn", "never"],
        "import/no-extraneous-dependencies": "off",
        "no-warning-comments": "warn",
        "no-constant-binary-expression": "warn",
        "import-x/no-unresolved": "off",
        "n/no-unsupported-features/node-builtins": "off",
    },
}]);

const lombiqRules = lombiqConfig[0].rules;

// Forwards compatibility for Stylistic for rules that exist with or without the "@stylistic/" prefix.
[
  'brace-style',
  'comma-dangle',
  'function-call-argument-newline',
  'function-paren-newline',
  'indent',
  'linebreak-style',
  'max-len',
  'no-alert',
  'operator-linebreak',
  'prefer-template',
  'wrap-iife',
]
    .forEach((key) => lombiqRules["@stylistic/" + key] = lombiqRules[key]);

const ignores = [
  '**/bin',
  '**/vendor/**/*.js',
  '**/vendor/**/*.cjs',
  '**/vendor/**/*.mjs',
  '**/eslint.*.mjs',
  ...(fs.existsSync('.eslintignore') ? includeIgnoreFile(path.resolve('.', '.eslintignore')).ignores : []),
];

const jsConfig = [
  // ESLint Recommended Rules
  {
    name: 'js/config',
    ...js.configs.recommended,
  },
  // Stylistic Plugin
  plugins.stylistic,
  // Import X Plugin
  plugins.importX,
  // Airbnb Base Recommended Config
  ...configs.base.recommended,
];

const nodeConfig = [
  // Node Plugin
  plugins.node,
  // Airbnb Node Recommended Config
  ...configs.node.recommended,
];

const custom = fs.existsSync('eslint.custom.mjs')
    ? await import('./eslint.custom.mjs')
    : [];

export default [
  // Ignore .gitignore files/folder in eslint
  { ignores },
  // Javascript Config
  ...jsConfig,
  // Node Config
  ...nodeConfig,
  // Our custom config, based on Lombiq.NodeJs.Extensions.
  ...lombiqConfig,
  // Additional custom configuration in the solution root.
  ...custom,
];
