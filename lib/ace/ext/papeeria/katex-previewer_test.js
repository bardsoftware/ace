if (typeof process !== "undefined") {
    require("amd-loader");
    require("../../test/mockdom");
}

define(function(require, exports, module) {
    var EditSession = require("ace/edit_session").EditSession;
    var Editor = require("ace/editor").Editor;
    var MockRenderer = require("ace/test/mockrenderer").MockRenderer;
    var Range = require("ace/range").Range
    var TokenIterator = require("ace/token_iterator").TokenIterator;
    var assert = require("ace/test/assertions");
    var KatexPreviewer = require("ace/ext/papeeria/katex-previewer.js")
    var EquationRangeHandler = KatexPreviewer.EquationRangeHandler;
    var ConstrainedTokenIterator = KatexPreviewer.ConstrainedTokenIterator;

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
            //
                    "\\end{equation}"]);
            // 3      012345678901234
            //        0         10
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRange = (new EquationRangeHandler(editor)).getEquationRange(2, 0);
            console.log(equationRange);

            assert.range(equationRange, 0, 16, 3, 0);
        },

        "test: ConstrainedTokenIterator, basic forward": function() {
            var session = new EditSession(["\\newline \\newline \\newline"]);
            //                               012345678 901234567 890123456
            //                               0          10         20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 5, 0, 20);
            var tokenIterator = new ConstrainedTokenIterator(session, range, 0, 15);
            assert.notEqual(tokenIterator.getCurrentToken(), null);

            tokenIterator.stepForward();
            assert.notEqual(tokenIterator.getCurrentToken(), null);

            tokenIterator.stepForward();
            assert.equal(tokenIterator.getCurrentToken(), null, JSON.stringify(tokenIterator.getCurrentToken()));
        },

        "test: ConstrainedTokenIterator, basic backward": function() {
            var session = new EditSession(["\\newline \\newline \\newline"]);
            //                               012345678 901234567 890123456
            //                               0          10         20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 5, 0, 20);
            var tokenIterator = new ConstrainedTokenIterator(session, range, 0, 15);
            assert.notEqual(tokenIterator.getCurrentToken(), null);

            tokenIterator.stepBackward();
            assert.notEqual(tokenIterator.getCurrentToken(), null);

            tokenIterator.stepBackward();
            assert.equal(tokenIterator.getCurrentToken(), null, JSON.stringify(tokenIterator.getCurrentToken()));
        },

        "test: ConstrainedTokenIterator, forward several times": function() {
            var session = new EditSession(["\\newline \\newline \\newline \\newline"]);
            //                               012345678 901234567 890123456 789012345
            //                               0          10         20         30
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 5, 0, 20);
            var tokenIterator = new ConstrainedTokenIterator(session, range, 0, 15);
            assert.notEqual(tokenIterator.getCurrentToken(), null);

            tokenIterator.stepForward();
            assert.notEqual(tokenIterator.getCurrentToken(), null);

            tokenIterator.stepForward();
            assert.equal(tokenIterator.getCurrentToken(), null, JSON.stringify(tokenIterator.getCurrentToken()));

            tokenIterator.stepForward();
            assert.equal(tokenIterator.getCurrentToken(), null, JSON.stringify(tokenIterator.getCurrentToken()));

            tokenIterator.stepBackward();
            assert.equal(tokenIterator.getCurrentToken(), null, JSON.stringify(tokenIterator.getCurrentToken()));

            tokenIterator.stepBackward();
            assert.notEqual(tokenIterator.getCurrentToken(), null);
        },

        "test: ConstrainedTokenIterator, backward several times": function() {
            var session = new EditSession(["\\newline \\newline \\newline \\newline"]);
            //                               012345678 901234567 890123456 789012345
            //                               0          10         20         30
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 15, 0, 30);
            var tokenIterator = new ConstrainedTokenIterator(session, range, 0, 20);
            assert.notEqual(tokenIterator.getCurrentToken(), null);

            tokenIterator.stepBackward();
            assert.notEqual(tokenIterator.getCurrentToken(), null);

            tokenIterator.stepBackward();
            assert.equal(tokenIterator.getCurrentToken(), null, JSON.stringify(tokenIterator.getCurrentToken()));

            tokenIterator.stepBackward();
            assert.equal(tokenIterator.getCurrentToken(), null, JSON.stringify(tokenIterator.getCurrentToken()));

            tokenIterator.stepForward();
            assert.equal(tokenIterator.getCurrentToken(), null, JSON.stringify(tokenIterator.getCurrentToken()));

            tokenIterator.stepForward();
            assert.notEqual(tokenIterator.getCurrentToken(), null);
        },

        "test: ConstrainedTokenIterator, exact range": function() {
            var session = new EditSession(["\\newline \\newline \\newline"]);
            //                               012345678 901234567 890123456 789012345
            //                               0          10         20         30
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 9, 0, 17);
            var tokenIterator = new ConstrainedTokenIterator(session, range, 0, 10);
            assert.notEqual(tokenIterator.getCurrentToken(), null);
        },

        "test: ConstrainedTokenIterator, starting out of range": function() {
            var session = new EditSession(["\\newline"]);
            //                               012345678
            //                               0
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 2, 0, 6);
            var tokenIterator = new ConstrainedTokenIterator(session, range, 0, 3);
            assert.equal(tokenIterator.getCurrentToken(), null);
        }
    }
});
