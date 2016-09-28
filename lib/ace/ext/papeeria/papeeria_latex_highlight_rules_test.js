if (typeof process !== "undefined") {
    require("amd-loader");
    require("../../test/mockdom");
}

define(function(require, exports, module) {
    var Tokenizer = require("ace/tokenizer").Tokenizer;
    var RulesModule = require("ace/ext/papeeria/papeeria_latex_highlight_rules");
    var PapeeriaLatexHighlightRules = RulesModule.PapeeriaLatexHighlightRules;
    var EQUATION_TOKEN_TYPE = RulesModule.EQUATION_TOKEN_TYPE;
    var MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE = RulesModule.MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE;
    var MATH_ENVIRONMENT_DISPLAYED_STATE = RulesModule.MATH_ENVIRONMENT_DISPLAYED_STATE;
    var MATH_TEX_INLINE_STATE = RulesModule.MATH_TEX_INLINE_STATE;
    var MATH_TEX_DISPLAYED_STATE = RulesModule.MATH_TEX_DISPLAYED_STATE;
    var MATH_LATEX_DISPLAYED_STATE = RulesModule.MATH_LATEX_DISPLAYED_STATE;
    var assert = require("ace/test/assertions");

    var isType = function(token, type) {
        return token.type.split(".").indexOf(type) > -1
    };

    module.exports = {
        "test: \"\\begin{equation}\": basic and mismatching ends": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var result = tokenizer.getLineTokens("\\begin{equation} $ $$ \\] \\end{equation*} x^2 \\text{hey} \\alpha \\$ % this is a comment", "start");
            var tokens = result.tokens;
            var state = result.state;

            assert.ok(state.length);
            // the first 4 tokens are `\begin{equation}`
            for (var i = 4; i < tokens.length; i++) {
                assert(isType(tokens[i], EQUATION_TOKEN_TYPE));
            }
        },

        "test: \"\\begin{equation*}\": basic and mismatching ends": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var result = tokenizer.getLineTokens("\\begin{equation*} $ $$ \\] \\end{equation} x^2 \\text{hey} \\alpha \\$ % this is a comment", "start");
            var tokens = result.tokens;
            var state = result.state;

            assert.ok(state.length);
            // the first 4 tokens are `\begin{equation}`
            for (var i = 4; i < tokens.length; i++) {
                assert(isType(tokens[i], EQUATION_TOKEN_TYPE));
            }
        },

        "test: \\[: basic and mismatching ends": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var result = tokenizer.getLineTokens("\\[ \\end{equation} \\end{equation*} $ $$ x^2 \\text{hey} \\alpha \\$ % this is a comment", "start");
            var tokens = result.tokens;
            var state = result.state;

            assert.ok(state.length);
            // the first token is `\[`
            for (var i = 1; i < tokens.length; i++) {
                assert(isType(tokens[i], EQUATION_TOKEN_TYPE));
            }
        },

        "test: $: basic and mismatching ends": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var result = tokenizer.getLineTokens("$ \\end{equation} \\end{equation*} \\] x^2 \\text{hey} \\alpha \\$ % this is a comment", "start");
            var tokens = result.tokens;
            var state = result.state;

            assert.ok(state.length);
            // the first token is `$`
            for (var i = 1; i < tokens.length; i++) {
                assert(isType(tokens[i], EQUATION_TOKEN_TYPE));
            }
        },

        "test: nested equation starts": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            // `$` and `$$` are trickier and are already tested for this in other tests
            var equationStates = [
                MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE,
                MATH_ENVIRONMENT_DISPLAYED_STATE,
                MATH_LATEX_DISPLAYED_STATE
            ]
            var equationStarts = ["\\begin{equation}", "\\begin{equation*}", "\\["];
            var result;

            for (var i = 0; i < equationStates.length; i++) {
                for (var j = 0; j < equationStarts.length; j++) {
                    if (i === j) {
                        continue;
                    }
                    result = tokenizer.getLineTokens(equationStarts[j] + "\\alpha", equationStates[i]);
                    assert.equal(result.state, equationStates[i]);
                }
            }
        },

        "test: $$: basic and mismatching ends": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var result = tokenizer.getLineTokens("$$ $ \\end{equation} \\end{equation*} \\] x^2 \\text{hey} \\alpha \\$ % this is a comment", "start");
            var tokens = result.tokens;
            var state = result.state;

            assert.ok(state.length);
            // the first token is `$$`
            for (var i = 1; i < tokens.length; i++) {
                assert(isType(tokens[i], "equation"), JSON.stringify(tokens[i]));
            }
        },

        "test: $ \\alpha $$ \\beta $": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var result = tokenizer.getLineTokens("$\\alpha$$\\beta$", "start");
            var tokens = result.tokens;

            assert(!isType(tokens[0], "equation"));
            assert(isType(tokens[1], "equation"));
            assert(!isType(tokens[2], "equation"));
            assert(!isType(tokens[3], "equation"));
            assert(isType(tokens[4], "equation"));
            assert(!isType(tokens[5], "equation"));
        },

        "test: nested lists: enumerate inside itemize": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var result = tokenizer.getLineTokens("\\begin{itemize} \\item \\begin{enumerate} \\item hey", "start");
            var tokens = result.tokens;
            var state = result.state;

            assert.ok(state.length);
            assert.equal(state[state.length - 1], "list.enumerate");
        },

        "test: nested lists: itemize inside enumerate": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var result = tokenizer.getLineTokens("\\begin{enumerate} \\item \\begin{itemize} \\item hey", "start");
            var tokens = result.tokens;
            var state = result.state;

            assert.ok(state.length);
            assert.equal(state[state.length - 1], "list.itemize");
        },

        "test: mismatching ends in lists: enumerate inside itemize": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var result = tokenizer.getLineTokens("\\begin{itemize} \\end{enumerate} \\item", "start");
            var tokens = result.tokens;
            var state = result.state;

            assert.ok(state.length);
            assert.equal(state[state.length - 1], "list.itemize");
        },

        "test: mismatching ends in lists: itemize inside enumerate": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var result = tokenizer.getLineTokens("\\begin{enumerate} \\end{itemize} \\item", "start");
            var tokens = result.tokens;
            var state = result.state;

            assert.ok(state.length);
            assert.equal(state[state.length - 1], "list.enumerate");
        },

        "test: equations in lists": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var result;

            result = tokenizer.getLineTokens("$\\alpha$", "list.itemize");
            assert(isType(result.tokens[1], "equation"));

            result = tokenizer.getLineTokens("$$\\beta$$", "list.itemize");
            assert(isType(result.tokens[1], "equation"));

            result = tokenizer.getLineTokens("\\[\\gamma\\]", "list.itemize");
            assert(isType(result.tokens[1], "equation"));

            result = tokenizer.getLineTokens("\\begin{equation}\\delta\\end{equation}", "list.itemize");
            assert(isType(result.tokens[4], "equation"));

            result = tokenizer.getLineTokens("$\\alpha$", "list.enumerate");
            assert(isType(result.tokens[1], "equation"));

            result = tokenizer.getLineTokens("$$\\beta$$", "list.enumerate");
            assert(isType(result.tokens[1], "equation"));

            result = tokenizer.getLineTokens("\\[\\gamma\\]", "list.enumerate");
            assert(isType(result.tokens[1], "equation"));

            result = tokenizer.getLineTokens("\\begin{equation}\\delta\\end{equation}", "list.enumerate");
            assert(isType(result.tokens[4], "equation"));
        }
    };
});
