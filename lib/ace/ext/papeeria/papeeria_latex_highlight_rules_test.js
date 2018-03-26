if (typeof process !== "undefined") {
    require("amd-loader");
    require("../../test/mockdom");
}

define(function(require, exports, module) {
    var Tokenizer = require("ace/tokenizer").Tokenizer;
    var RulesModule = require("ace/ext/papeeria/papeeria_latex_highlight_rules");
    var PapeeriaLatexHighlightRules = RulesModule.PapeeriaLatexHighlightRules;
    var EQUATION_TOKENTYPE = RulesModule.EQUATION_TOKENTYPE;
    var LIST_TOKENTYPE = RulesModule.LIST_TOKENTYPE;
    var STORAGE_TOKENTYPE = RulesModule.STORAGE_TOKENTYPE;
    var KEYWORD_TOKENTYPE = RulesModule.KEYWORD_TOKENTYPE;
    var LPAREN_TOKENTYPE = RulesModule.LPAREN_TOKENTYPE;
    var RPAREN_TOKENTYPE = RulesModule.RPAREN_TOKENTYPE;
    var MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE = RulesModule.MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE;
    var MATH_ENVIRONMENT_DISPLAYED_STATE = RulesModule.MATH_ENVIRONMENT_DISPLAYED_STATE;
    var MATH_TEX_INLINE_STATE = RulesModule.MATH_TEX_INLINE_STATE;
    var MATH_TEX_DISPLAYED_STATE = RulesModule.MATH_TEX_DISPLAYED_STATE;
    var MATH_LATEX_INLINE_STATE = RulesModule.MATH_LATEX_INLINE_STATE;
    var MATH_LATEX_DISPLAYED_STATE = RulesModule.MATH_LATEX_DISPLAYED_STATE;
    var assert = require("ace/test/assertions");

    var isType = function(token, type) {
        return token.type.indexOf(type) > -1
    };


    var mathConstants = {};
    mathConstants[MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE] = {
        "start"  : "\\begin{equation}",
        "end"    :"\\end{equation}",
        "length" :4
    };
    mathConstants[MATH_ENVIRONMENT_DISPLAYED_STATE] = {
        "start"  : "\\begin{equation*}",
        "end"    : "\\end{equation*}",
        "length" : 4
    };
    mathConstants[MATH_TEX_INLINE_STATE] = {
        "start"  : "$",
        "end"    : "$",
        "length" : 1
    };
    mathConstants[MATH_TEX_DISPLAYED_STATE] = {
        "start"  : "$$",
        "end"    : "$$",
        "length" : 1
    };
    mathConstants[MATH_LATEX_INLINE_STATE] = {
        "start"  : "\\(",
        "end"    : "\\)",
        "length" : 1
    };
    mathConstants[MATH_LATEX_DISPLAYED_STATE] = {
        "start"  : "\\[",
        "end"    : "\\]",
        "length" : 1
    };

    module.exports = {
        "test: entering equation state": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            // we do not append closing string in this test, because we only
            // test entering the equation state here
            var basicString = " x^2 \\text{hey} \\alpha \\$ % this is a comment";
            for (var state in mathConstants) {
                var stateConstants = mathConstants[state];
                var testString = stateConstants.start + basicString;
                var result = tokenizer.getLineTokens(testString);
                var tokens = result.tokens;
                var state = result.state;
                assert.ok(state.length);
                for (var i = stateConstants.length; i < tokens.length; i++) {
                    assert(isType(tokens[i], EQUATION_TOKENTYPE), state);
                }
            }
        },

        "test: exiting equation state": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            for (var state in mathConstants) {
                var stateConstants = mathConstants[state];
                var testString = stateConstants.end;
                var result = tokenizer.getLineTokens(testString, [state]);
                assert.equal(result.state, "start");
            }
        },

        "test: mismatching ends": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);

            for (var startState in mathConstants) {
                var startConstants = mathConstants[startState];
                for (var endState in mathConstants) {
                    var endConstants = mathConstants[endState];
                    if (endConstants.end.startsWith(startConstants.end)) {
                        continue;
                    }

                    var testString = startConstants.start + " " + endConstants.end;
                    var result = tokenizer.getLineTokens(testString);
                    assert.equal(result.state[result.state.length - 1], startState);
                }
            }
        },

        "test: nested equation starts": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);

            for (var initState in mathConstants) {
                var initStateConstants = mathConstants[initState];
                for (var innerState in mathConstants) {
                    // second condition is for skipping testing `$$`
                    // inside the equation state delimited with `$`
                    // because `$$` will and should be parsed as an
                    // end of this state (and then one more `$`)
                    if (innerState === initState || (initState === MATH_TEX_INLINE_STATE && innerState === MATH_TEX_DISPLAYED_STATE)) {
                        continue;
                    }
                    var innerStateConstants = mathConstants[innerState];

                    var result = tokenizer.getLineTokens(innerStateConstants.start, initState);
                    assert.equal(result.state, initState);
                }
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

            for (var state in mathConstants) {
                stateConstants = mathConstants[state];
                var result = tokenizer.getLineTokens(stateConstants.start + " \\alpha", "list.itemize");
                assert.equal(result.state[result.state.length - 1], state);
            }
        },

        "test: cite tags empty": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var commands = [RulesModule.CITE_COMMAND, RulesModule.REF_COMMAND, RulesModule.VCITE_COMMAND, RulesModule.VREF_COMMAND];
            var tokentypes = [RulesModule.CITE_TOKENTYPE, RulesModule.REF_TOKENTYPE, RulesModule.VCITE_TOKENTYPE, RulesModule.VREF_TOKENTYPE];
            for (var i = 0; i < commands.length; ++i) {
                var result = tokenizer.getLineTokens("\\" + commands[i] + "{}", "start");
                var tokens = result.tokens;

                assert(isType(tokens[1], tokentypes[i]));
                assert(isType(tokens[1], "lparen"));
            }
        },

        "test: cite tags filled": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var commands = [RulesModule.CITE_COMMAND, RulesModule.REF_COMMAND, RulesModule.VCITE_COMMAND, RulesModule.VREF_COMMAND];
            var tokentypes = [RulesModule.CITE_TOKENTYPE, RulesModule.REF_TOKENTYPE, RulesModule.VCITE_TOKENTYPE, RulesModule.VREF_TOKENTYPE];
            for (var i = 0; i < commands.length; ++i) {
                var result = tokenizer.getLineTokens("\\" + commands[i] + "{foo, bar}", "start");
                var tokens = result.tokens;

                assert(isType(tokens[2], tokentypes[i]));
                assert(isType(tokens[2], "parameter"));
                assert.equal("foo, bar", tokens[2].value);
            }
        },

        "test: cite tags closes": function() {
            var rules = new PapeeriaLatexHighlightRules().getRules();
            var tokenizer = new Tokenizer(rules);
            var commands = [RulesModule.CITE_COMMAND, RulesModule.REF_COMMAND, RulesModule.VCITE_COMMAND, RulesModule.VREF_COMMAND];
            var tokentypes = [RulesModule.CITE_TOKENTYPE, RulesModule.REF_TOKENTYPE, RulesModule.VCITE_TOKENTYPE, RulesModule.VREF_TOKENTYPE];
            for (var i = 0; i < commands.length; ++i) {
                var result = tokenizer.getLineTokens("\\" + commands[i] + "{foo, bar} baz", "start");
                var tokens = result.tokens;

                assert(!isType(tokens[4], tokentypes[i]));
                assert.equal(" baz", tokens[4].value);
            }
        },

        "test: spaces in 'begin' and 'end'": function() {
            var tokenizer = new Tokenizer(new PapeeriaLatexHighlightRules().getRules());

            var beginEndParameters = [
                ["equation", EQUATION_TOKENTYPE],
                ["equation*", EQUATION_TOKENTYPE],
                ["itemize", LIST_TOKENTYPE],
                ["enumerate", LIST_TOKENTYPE]
            ];

            for (var i = 0; i < beginEndParameters.length; ++i) {
                var param = beginEndParameters[i][0];
                var tokentype = beginEndParameters[i][1];
                var line = "\\begin {" + param + "} hi \\end {" + param + "}";
                var result = tokenizer.getLineTokens(line, "start").tokens;
                assert(isType(result[0], STORAGE_TOKENTYPE));
                assert(isType(result[2], "variable.parameter"));
                assert(isType(result[4], tokentype));
                assert(isType(result[5], STORAGE_TOKENTYPE));
                assert(isType(result[7], "variable.parameter"));
            }

            var line = "\\begin {someenv} hi \\end {someenv}"
            var result = tokenizer.getLineTokens(line, "start").tokens;
            assert(isType(result[0], STORAGE_TOKENTYPE));
            assert(isType(result[2], "variable.parameter"));
            assert(isType(result[5], STORAGE_TOKENTYPE));
            assert(isType(result[7], "variable.parameter"));
        },

        "test: spaces in 'ref' and 'cite'": function() {
            var tokenizer = new Tokenizer(new PapeeriaLatexHighlightRules().getRules());

            var result;

            result = tokenizer.getLineTokens("\\ref {smth}", "start").tokens;
            assert(isType(result[0], STORAGE_TOKENTYPE));
            assert(isType(result[1], LPAREN_TOKENTYPE + ".ref"));
            assert(isType(result[2], "ref.parameter"));

            result = tokenizer.getLineTokens("\\cite {smth}", "start").tokens;
            assert(isType(result[0], STORAGE_TOKENTYPE));
            assert(isType(result[1], LPAREN_TOKENTYPE + ".cite"));
            assert(isType(result[2], "cite.parameter"));

            result = tokenizer.getLineTokens("\\vref {smth}", "start").tokens;
            assert(isType(result[0], STORAGE_TOKENTYPE));
            assert(isType(result[1], LPAREN_TOKENTYPE + ".vref"));
            assert(isType(result[2], "vref.parameter"));

            result = tokenizer.getLineTokens("\\vcite {smth}", "start").tokens;
            assert(isType(result[0], STORAGE_TOKENTYPE));
            assert(isType(result[1], LPAREN_TOKENTYPE + ".vcite"));
            assert(isType(result[2], "vcite.parameter"));
        },

        "test: spaces in 'documentclass', 'usepackage' and 'input'": function() {
            var tokenizer = new Tokenizer(new PapeeriaLatexHighlightRules().getRules());

            var commands = [
                "documentclass",
                "usepackage",
                "input"
            ];

            for (var i = 0; i < commands.length; ++i) {
                var command = commands[i];
                var line = "\\" + command + " [smth] {smth}";
                var result = tokenizer.getLineTokens(line, "start").tokens;
                assert(isType(result[0], KEYWORD_TOKENTYPE));
                assert(isType(result[1], LPAREN_TOKENTYPE));
                assert(isType(result[2], "variable.parameter"));
                assert(isType(result[3], RPAREN_TOKENTYPE));
                assert(isType(result[4], LPAREN_TOKENTYPE));
                assert(isType(result[5], STORAGE_TOKENTYPE + ".type"));
                assert(isType(result[6], RPAREN_TOKENTYPE));
            }
        }
    };
});
