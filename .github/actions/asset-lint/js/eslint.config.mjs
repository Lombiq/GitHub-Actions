import path from 'node:path';
import { includeIgnoreFile } from '@eslint/compat';
import js from '@eslint/js';
import { configs, plugins } from 'eslint-config-airbnb-extended';
import { defineConfig } from 'eslint/config';
import globals from 'globals';
import onlyWarn from 'eslint-plugin-only-warn';

const lombiqConfig = defineConfig([{
    plugins: {
        "only-warn": onlyWarn,
    },

    languageOptions: {
        globals: {
            ...globals.jquery,
            ...globals.browser,
        },

        ecmaVersion: 2020,
        sourceType: "script",
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

        indent: ["warn", 4, {
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
        strict: ["warn", "safe"],
        "import/no-extraneous-dependencies": "off",
        "no-warning-comments": "warn",
        "no-constant-binary-expression": "warn",
        "import/no-unresolved": "off",
    },
}]);

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
  ...lombiqConfig,
];

const nodeConfig = [
  // Node Plugin
  plugins.node,
  // Airbnb Node Recommended Config
  ...configs.node.recommended,
];

export default [
  // Ignore .eslintignore files/folder in eslint
  includeIgnoreFile(path.resolve('.', '.eslintignore')),
  // Javascript Config
  ...jsConfig,
  // Node Config
  ...nodeConfig,
];
