if (typeof process !== "undefined") {
    require("amd-loader");
    require("../../test/mockdom");
}

define(function(require, exports, module) {
    var EditSession = require("ace/edit_session").EditSession;
    var Editor = require("ace/editor").Editor;
    var MockRenderer = require("ace/test/mockrenderer").MockRenderer;
    var LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context");
    var PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules").PapeeriaLatexHighlightRules;
    var Tokenizer = require("ace/tokenizer").Tokenizer;
    var PapeeriaLatexMode = {
        getTokenizer: function() {
            return new Tokenizer((new PapeeriaLatexHighlightRules()).getRules());
        }
    };
    var assert = require("ace/test/assertions");

    module.exports = {
        "test: any environment state": function() {
            var session = new EditSession(["\\begin{}", "", "\\end{}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode(PapeeriaLatexMode);
            assert.equal("environment", LatexParsingContext.getContext(session, 0, 7));
        }
    }
});
