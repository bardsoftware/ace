if (typeof process !== "undefined") {
    require("amd-loader");
    require("../../test/mockdom");
}

define(function(require, exports, module) {
    var EditSession = require("ace/edit_session").EditSession;
    var Editor = require("ace/editor").Editor;
    var MockRenderer = require("ace/test/mockrenderer").MockRenderer;
    var TokenIterator = require("ace/token_iterator").TokenIterator;
    var assert = require("ace/test/assertions");
    var getEquationRangeHandler = require("ace/ext/papeeria/katex-previewer.js").getEquationRangeHandler;

    module.exports = {
        "test: inside the sequence": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = getEquationRangeHandler(editor).getEquationRange(0, 30);

            assert.range(equationRange, 0, 16, 0, 34);
        },

        "test: on the edge of start": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = getEquationRangeHandler(editor).getEquationRange(0, 16);

            assert.range(equationRange, 0, 16, 0, 34);
        },

        "test: on the edge of end": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = getEquationRangeHandler(editor).getEquationRange(0, 35);

            assert.range(equationRange, 0, 16, 0, 34);
        },

        "test: inside the start": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = getEquationRangeHandler(editor).getEquationRange(0, 5);

            assert.range(equationRange, 0, 16, 0, 34);
        },

        "test: inside the end": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = getEquationRangeHandler(editor).getEquationRange(0, 40);

            assert.range(equationRange, 0, 16, 0, 34);
        },

        "test: on the empty string": function() {
            var session = new EditSession(["\\begin{equation}", "\\text{hi there!}", "", "\\end{equation}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = getEquationRangeHandler(editor).getEquationRange(2, 0);
            console.log(equationRange);

            assert.range(equationRange, 0, 16, 3, 0);
        }
    }
});
