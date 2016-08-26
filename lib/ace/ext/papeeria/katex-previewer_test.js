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
    var EquationRangeHandler = require("ace/ext/papeeria/katex-previewer.js").EquationRangeHandler;

    module.exports = {
        "test: EquationRangeHandler, inside the sequence": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234567890123 4567890123456789
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = (new EquationRangeHandler(editor)).getEquationRange(0, 30);

            assert.range(equationRange, 0, 16, 0, 34);
        },

        "test: EquationRangeHandler, on the edge of start": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234567890123 4567890123456789
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = (new EquationRangeHandler(editor)).getEquationRange(0, 16);

            assert.range(equationRange, 0, 16, 0, 34);
        },

        "test: EquationRangeHandler, on the edge of end": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234567890123 4567890123456789
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = (new EquationRangeHandler(editor)).getEquationRange(0, 35);

            assert.range(equationRange, 0, 16, 0, 34);
        },

        "test: EquationRangeHandler, inside the start": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234567890123 4567890123456789
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = (new EquationRangeHandler(editor)).getEquationRange(0, 5);

            assert.range(equationRange, 0, 16, 0, 34);
        },

        "test: EquationRangeHandler, inside the end": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234567890123 4567890123456789
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = (new EquationRangeHandler(editor)).getEquationRange(0, 40);

            assert.range(equationRange, 0, 16, 0, 34);
        },

        "test: EquationRangeHandler, on the empty string": function() {
            var session = new EditSession([
                    "\\begin{equation}",
            // 0      01234567890123456
            //        0         10
                    "\\text{hi there!}",
            // 1      01234567890123456
            //        0         10
                    "",
            // 2
                    "\\end{equation}"]);
            // 3      012345678901234
            //        0         10
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = (new EquationRangeHandler(editor)).getEquationRange(2, 0);
            console.log(equationRange);

            assert.range(equationRange, 0, 16, 3, 0);
        }
    }
});
