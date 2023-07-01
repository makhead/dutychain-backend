/*
 * SPDX-License-Identifier: Apache-2.0
 */
"use strict";

module.exports = {
	env: {
		node: true,
		mocha: true,
		es6: true,
	},
	parserOptions: {
		ecmaVersion: 8,
		sourceType: "script",
	},
	extends: "eslint:recommended",
	rules: {
		"no-console": "off",
		curly: "error",
		eqeqeq: "error",
		"no-throw-literal": "error",
		"no-use-before-define": "error",
		"no-useless-call": "error",
		"no-with": "error",
		"operator-linebreak": "error",
		yoda: "error",
	},
};
