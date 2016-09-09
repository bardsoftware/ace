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
    var ContextHandler = KatexPreviewer.ContextHandler;

    module.exports = {
        "test: EquationRangeHandler, inside \\begin{equation} \\end{equation}": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234567890123 456789012345678
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 30);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 48);
            assert.range(equationInnerRange, 0, 16, 0, 34);
        },

        "test: EquationRangeHandler, on the edge of \\begin{equation}": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234567890123 456789012345678
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 16);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 48);
            assert.range(equationInnerRange, 0, 16, 0, 34);
        },

        "test: EquationRangeHandler, on the edge of \\end{equation}": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234567890123 456789012345678
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 34);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 48);
            assert.range(equationInnerRange, 0, 16, 0, 34);
        },

        "test: EquationRangeHandler, inside \\begin{equation}": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234567890123 456789012345678
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 5);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 48);
            assert.range(equationInnerRange, 0, 16, 0, 34);
        },

        "test: EquationRangeHandler, inside \\end{equation}": function() {
            var session = new EditSession(["\\begin{equation} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234567890123 456789012345678
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 40);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 48);
            assert.range(equationInnerRange, 0, 16, 0, 34);
        },

        "test: EquationRangeHandler, inside \\begin{equation*} \\end{equation*}": function() {
            var session = new EditSession(["\\begin{equation*} \\text{hi there!} \\end{equation*}"]);
            //                               012345678901234567 89012345678901234 5678901234567890
            //                               0         10         20        30         40        50
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 30);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 50);
            assert.range(equationInnerRange, 0, 17, 0, 35);
        },

        "test: EquationRangeHandler, on the edge of \\begin{equation*}": function() {
            var session = new EditSession(["\\begin{equation*} \\text{hi there!} \\end{equation*}"]);
            //                               012345678901234567 89012345678901234 5678901234567890
            //                               0         10         20        30         40        50
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 17);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 50);
            assert.range(equationInnerRange, 0, 17, 0, 35);
        },

        "test: EquationRangeHandler, on the edge of \\end{equation*}": function() {
            var session = new EditSession(["\\begin{equation*} \\text{hi there!} \\end{equation*}"]);
            //                               012345678901234567 89012345678901234 5678901234567890
            //                               0         10         20        30         40        50
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 35);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 50);
            assert.range(equationInnerRange, 0, 17, 0, 35);
        },

        "test: EquationRangeHandler, inside \\begin{equation*}": function() {
            var session = new EditSession(["\\begin{equation*} \\text{hi there!} \\end{equation*}"]);
            //                               012345678901234567 89012345678901234 5678901234567890
            //                               0         10         20        30         40        50
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 5);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 50);
            assert.range(equationInnerRange, 0, 17, 0, 35);
        },

        "test: EquationRangeHandler, inside \\end{equation*}": function() {
            var session = new EditSession(["\\begin{equation*} \\text{hi there!} \\end{equation*}"]);
            //                               012345678901234567 89012345678901234 5678901234567890
            //                               0         10         20        30         40        50
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 40);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 50);
            assert.range(equationInnerRange, 0, 17, 0, 35);
        },

        "test: EquationRangeHandler, two in a row": function() {
            var session = new EditSession(["\\begin{equation*} 0 \\end{equation*} \\begin{equation} 1 \\end{equation}"]);
            //                               01234567890123456789 0123456789012345 6789012345678901234 567890123456789
            //                               0         10         20        30         40        50         60
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 18);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 35);
            assert.range(equationInnerRange, 0, 17, 0, 20);

            var equationRanges1 = (new EquationRangeHandler(editor)).getEquationRange(0, 53);
            var equationOuterRange1 = equationRanges1.outer;
            var equationInnerRange1 = equationRanges1.inner;

            assert.range(equationOuterRange1, 0, 36, 0, 69);
            assert.range(equationInnerRange1, 0, 52, 0, 55);
        },

        "test: EquationRangeHandler, inside \\[ \\]": function() {
            var session = new EditSession(["\\[ \\text{hi there!} \\]"]);
            //                               012 34567890123456789 012
            //                               0          10         20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 10);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 22);
            assert.range(equationInnerRange, 0, 2, 0, 20);
        },

        "test: EquationRangeHandler, on the edge of \\[": function() {
            var session = new EditSession(["\\[ \\text{hi there!} \\]"]);
            //                               012 34567890123456789 012
            //                               0          10         20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 3);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 22);
            assert.range(equationInnerRange, 0, 2, 0, 20);
        },

        "test: EquationRangeHandler, on the edge of \\]": function() {
            var session = new EditSession(["\\[ \\text{hi there!} \\]"]);
            //                               012 34567890123456789 012
            //                               0          10         20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 19);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 22);
            assert.range(equationInnerRange, 0, 2, 0, 20);
        },

        "test: EquationRangeHandler, inside $ $": function() {
            var session = new EditSession(["$ \\text{hi there!} $"]);
            //                              01 2345678901234567890
            //                              0          10        20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 10);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 20);
            assert.range(equationInnerRange, 0, 1, 0, 19);
        },

        "test: EquationRangeHandler, on the edge of starting $": function() {
            var session = new EditSession(["$ \\text{hi there!} $"]);
            //                              01 2345678901234567890
            //                              0          10        20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 2);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 20);
            assert.range(equationInnerRange, 0, 1, 0, 19);
        },

        "test: EquationRangeHandler, on the edge of ending $": function() {
            var session = new EditSession(["$ \\text{hi there!} $"]);
            //                              01 2345678901234567890
            //                              0          10        20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 18);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 20);
            assert.range(equationInnerRange, 0, 1, 0, 19);
        },

        "test: EquationRangeHandler, inside $$ $$": function() {
            var session = new EditSession(["$$ \\text{hi there!} $$"]);
            //                              012 34567890123456789012
            //                              0          10        20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 10);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 22);
            assert.range(equationInnerRange, 0, 2, 0, 20);
        },

        "test: EquationRangeHandler, on the edge of starting $$": function() {
            var session = new EditSession(["$$ \\text{hi there!} $$"]);
            //                              012 34567890123456789012
            //                              0          10        20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 3);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 22);
            assert.range(equationInnerRange, 0, 2, 0, 20);
        },

        "test: EquationRangeHandler, on the edge of ending $$": function() {
            var session = new EditSession(["$$ \\text{hi there!} $$"]);
            //                              012 34567890123456789012
            //                              0          10        20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(0, 19);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 0, 22);
            assert.range(equationInnerRange, 0, 2, 0, 20);
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
            // 2     0
            //       0
                    "\\end{equation}"]);
            // 3      012345678901234
            //        0         10
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(2, 0);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.range(equationOuterRange, 0, 0, 3, 14);
            assert.range(equationInnerRange, 0, 16, 3, 0);
        },

        "test: EquationRangeHandler, after the end of a document": function() {
            var session = new EditSession([
                    "\\begin{equation}",
            // 0      01234567890123456
            //        0         10
                    "\\end{equation}"]);
            // 1      012345678901234
            //        0         10
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(3, 0);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.equal(equationOuterRange, null);
            assert.equal(equationInnerRange, null);
        },

        "test: EquationRangeHandler, before the start of a document": function() {
            var session = new EditSession([
                    "\\begin{equation}",
            // 0      01234567890123456
            //        0         10
                    "\\end{equation}"]);
            // 1      012345678901234
            //        0         10
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var equationRanges = (new EquationRangeHandler(editor)).getEquationRange(-1, 0);
            var equationOuterRange = equationRanges.outer;
            var equationInnerRange = equationRanges.inner;

            assert.equal(equationOuterRange, null);
            assert.equal(equationInnerRange, null);
        },

        "test: ContextHandler.getWholeEquation, no labels": function() {
            var session = new EditSession(["\\begin{equation}\\text{hi there!}\\end{equation}"]);
            //                               0123456789012345 6789012345678901 23456789012345678
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 16, 0, 34);
            var tokenIterator = new ConstrainedTokenIterator(session, range, 0, 16);
            tokenIterator.stepForward();

            var labelsAndEquation = ContextHandler.getWholeEquation(session, tokenIterator);

            assert.deepEqual(labelsAndEquation.params, []);
            assert.equal(labelsAndEquation.equation, "\\text{hi there!}");
        },

        "test: ContextHandler.getWholeEquation, two labels": function() {
            var session = new EditSession(["\\begin{equation} \\label{label1} \\label{label2} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 789012345678901 234567890123456 78901234567890123 456789012345678
            //                               0         10         20        30         40         50        60         70
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 16, 0, 64);
            var tokenIterator = new ConstrainedTokenIterator(session, range, 0, 16);
            tokenIterator.stepForward();

            var labelsAndEquation = ContextHandler.getWholeEquation(session, tokenIterator);

            assert.deepEqual(labelsAndEquation.params, ["label1", "label2"]);
            assert.equal(labelsAndEquation.equation, "   \\text{hi there!} ");
        },

        "test: ContextHandler.getWholeEquation, wrong label": function() {
            var session = new EditSession(["\\begin{equation} \\label{ \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234 56789012345678901 234567890123456
            //                               0         10         20         30        40         50
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 16, 0, 42);
            var tokenIterator = new ConstrainedTokenIterator(session, range, 0, 16);
            tokenIterator.stepForward();

            var labelsAndEquation = ContextHandler.getWholeEquation(session, tokenIterator);

            assert.deepEqual(labelsAndEquation.params, []);
            assert.equal(labelsAndEquation.equation, " \\label{ \\text{hi there!} ");
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
            //                               012345678 901234567 890123456
            //                               0          10         20
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
