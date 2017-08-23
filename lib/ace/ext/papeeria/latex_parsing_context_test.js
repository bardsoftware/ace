if (typeof process !== "undefined") {
    require("amd-loader");
    require("../../test/mockdom");
}

define(function(require, exports, module) {
    var EditSession = require("ace/edit_session").EditSession;
    var Editor = require("ace/editor").Editor;
    var MockRenderer = require("ace/test/mockrenderer").MockRenderer;
    var LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context");
    var RulesModule = require("ace/ext/papeeria/papeeria_latex_highlight_rules");
    var PapeeriaLatexHighlightRules = RulesModule.PapeeriaLatexHighlightRules;
    var Tokenizer = require("ace/tokenizer").Tokenizer;
    var PapeeriaLatexMode = {
        getTokenizer: function() {
            return new Tokenizer((new PapeeriaLatexHighlightRules()).getRules());
        }
    };
    var assert = require("ace/test/assertions");
    var session;
    var editor;
    var setupSession = function(strings) {
        session = new EditSession(strings);
        editor = new Editor(new MockRenderer(), session);
        session.setMode(PapeeriaLatexMode);
    };
    var testContext = function(row, column, context) {
        assert.equal(context, LatexParsingContext.getContext(session, row, column));
    };

    module.exports = {
        "test: comments": function() {
            //             012345
            setupSession(["% hey"]);
            testContext(0, 4, RulesModule.COMMENT_TOKENTYPE);
        },

        "test: equation": function() {
            //             01234567890
            setupSession(["$$ hey %hi", "$$"]);
            testContext(0, 5, RulesModule.EQUATION_TOKENTYPE);
            testContext(0, 9, RulesModule.EQUATION_TOKENTYPE);
            //
            //              0         1          2          3         4
            //              0123456789012345 678901234567 89012345678901
            setupSession(["\\begin{itemize} \\item $hey$ \\end{itemize}"]);
            testContext(0, 24, RulesModule.EQUATION_TOKENTYPE);
        },

        "test: environment": function() {
            setupSession(["\\begin{}", "", "\\end{}"]);
            testContext(0, 7, RulesModule.ENVIRONMENT_TOKENTYPE);
        },

        "test: list": function() {
            //              0         1          2          3         4
            //              0123456789012345 678901234567 89012345678901
            setupSession(["\\begin{itemize} \\item hey \\end{itemize}"]);
            testContext(0, 24, RulesModule.LIST_TOKENTYPE);
        },

        "test: start of the state": function() {
            //             012345
            setupSession(["$hey$"]);
            testContext(0, 1, RulesModule.EQUATION_TOKENTYPE);

            setupSession(["$", "hey$"]);
            testContext(0, 1, RulesModule.EQUATION_TOKENTYPE);
        },

        "test: start of a line": function() {
            setupSession(["$", "hey$"]);
            testContext(1, 0, RulesModule.EQUATION_TOKENTYPE);
            setupSession(["hi", "%hey"]);
            testContext(1, 0, RulesModule.START_STATE);
        },

        "test: empty line": function() {
            setupSession(["$", ""]);
            testContext(1, 0, RulesModule.EQUATION_TOKENTYPE);
        }
    }
});
