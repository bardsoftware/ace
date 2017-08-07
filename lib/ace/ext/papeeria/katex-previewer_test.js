if (typeof process !== "undefined") {
    require("amd-loader");
    require("../../test/mockdom");
}

define(function(require, exports, module) {
    var EditSession = require("ace/edit_session").EditSession;
    var Editor = require("ace/editor").Editor;
    var MockRenderer = require("ace/test/mockrenderer").MockRenderer;
    var Range = require("ace/range").Range;
    var TokenIterator = require("ace/token_iterator").TokenIterator;
    var assert = require("ace/test/assertions");
    var KatexPreviewer = require("ace/ext/papeeria/katex-previewer");
    var EquationRangeHandler = KatexPreviewer.testExport.EquationRangeHandler;
    var ContextHandler = KatexPreviewer.testExport.ContextHandler;
    var RulesModule = require("ace/ext/papeeria/papeeria_latex_highlight_rules");
    var PapeeriaLatexHighlightRules = RulesModule.PapeeriaLatexHighlightRules;
    var EQUATION_TOKEN_TYPE = RulesModule.EQUATION_TOKEN_TYPE;
    var MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE = RulesModule.MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE;
    var MATH_ENVIRONMENT_DISPLAYED_STATE = RulesModule.MATH_ENVIRONMENT_DISPLAYED_STATE;
    var MATH_TEX_INLINE_STATE = RulesModule.MATH_TEX_INLINE_STATE;
    var MATH_TEX_DISPLAYED_STATE = RulesModule.MATH_TEX_DISPLAYED_STATE;
    var MATH_LATEX_INLINE_STATE = RulesModule.MATH_LATEX_INLINE_STATE;
    var MATH_LATEX_DISPLAYED_STATE = RulesModule.MATH_LATEX_DISPLAYED_STATE;

    var mathConstants = {};
    mathConstants[MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE] = {
        "start"  : "\\begin{equation}",
        "end"    : "\\end{equation}",
    };
    mathConstants[MATH_ENVIRONMENT_DISPLAYED_STATE] = {
        "start"  : "\\begin{equation*}",
        "end"    : "\\end{equation*}",
    };
    mathConstants[MATH_TEX_INLINE_STATE] = {
        "start"  : "$",
        "end"    : "$",
    };
    mathConstants[MATH_TEX_DISPLAYED_STATE] = {
        "start"  : "$$",
        "end"    : "$$",
    };
    mathConstants[MATH_LATEX_INLINE_STATE] = {
        "start"  : "\\(",
        "end"    : "\\)",
    };
    mathConstants[MATH_LATEX_DISPLAYED_STATE] = {
        "start"  : "\\[",
        "end"    : "\\]",
    };

    var MockPopoverHandler = function() {
        this.options = {
            html: true,
            placement: "bottom",
            trigger: "manual"
        };

        this.show = function(title, content, position) {
            this.title = title;
            this.content = content;
            this.position = position;
            this.shown = true;
        };

        this.destroy = function() {
            this.title = null;
            this.content = null;
            this.position = null;
            this.shown = false;
        };

        this.setContent = function(title, content) {
            this.title = title;
            this.content = content;
        };

        this.setPosition = function(position) {
            this.position = position;
        };
    };


    module.exports = {
        "test: EquationRangeHandler, inside math": function() {
            var session = new EditSession([]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var content = "\\alpha";

            for (var state in mathConstants) {
                var stateConstants = mathConstants[state];
                var line = stateConstants.start + content + stateConstants.end;
                session.insert({ row: session.getLength(), column: 0 }, "\n" + line);
                var row = session.getLength() - 1;
                var equationStart = stateConstants.start.length;
                var equationEnd = equationStart + content.length;

                var equationRange = new EquationRangeHandler(editor).getEquationRange(row, equationStart + 1);

                assert(equationRange.correct);
                assert.range(equationRange.range, row, equationStart, row, equationEnd);
            }
        },

        "test: EquationRangeHandler, on the edge of end math": function() {
            var session = new EditSession([]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var content = "\\alpha";

            for (var state in mathConstants) {
                var stateConstants = mathConstants[state];
                var line = stateConstants.start + content + stateConstants.end;
                session.insert({ row: session.getLength(), column: 0 }, "\n" + line);
                var row = session.getLength() - 1;
                var equationStart = stateConstants.start.length;
                var equationEnd = equationStart + content.length;

                var equationRange = new EquationRangeHandler(editor).getEquationRange(row, equationEnd);

                assert(equationRange.correct);
                assert.range(equationRange.range, row, equationStart, row, equationEnd);
            }
        },

        "test: EquationRangeHandler, ending with empty line with some text after": function() {
            var content = "\\alpha";

            for (var state in mathConstants) {
                var stateConstants = mathConstants[state];
                var session = new EditSession([stateConstants.start + content, "", "stuff"]);
                var editor = new Editor(new MockRenderer(), session);
                session.setMode("./mode/papeeria_latex");

                var equationStart = stateConstants.start.length;
                var equationEnd = equationStart + content.length;

                var equationRange = new EquationRangeHandler(editor).getEquationRange(1, 0);

                assert(!equationRange.correct);
                assert.range(equationRange.range, 0, equationStart, 1, 0);
            }
        },

        "test: EquationRangeHandler, ending with the end of a file": function() {
            var session = new EditSession([]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var content = "\\alpha";

            for (var state in mathConstants) {
                var stateConstants = mathConstants[state];
                var line = stateConstants.start + content;
                session.insert({ row: session.getLength(), column: 0 }, "\n" + line);
                var row = session.getLength() - 1;
                var equationStart = stateConstants.start.length;
                var equationEnd = equationStart + content.length;

                var equationRange = new EquationRangeHandler(editor).getEquationRange(row, equationStart + 1);

                assert(!equationRange.correct);
                assert.range(equationRange.range, row, equationStart, row, equationEnd);
            }
        },

        "test: ContextHandler.extractEquation, no labels": function() {
            var session = new EditSession(["\\begin{equation}\\text{hi there!}\\end{equation}"]);
            //                               0123456789012345 6789012345678901 23456789012345678
            //                               0         10         20        30         40
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 16, 0, 32);

            var labelsAndEquation = ContextHandler.extractEquation(session, range);

            assert.deepEqual(labelsAndEquation.labels, []);
            assert.equal(labelsAndEquation.equation, "\\text{hi there!}");
        },

        "test: ContextHandler.extractEquation, two labels": function() {
            var session = new EditSession(["\\begin{equation} \\label{label1} \\label{label2} \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 789012345678901 234567890123456 78901234567890123 456789012345678
            //                               0         10         20        30         40         50        60         70
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 16, 0, 64);

            var labelsAndEquation = ContextHandler.extractEquation(session, range);

            assert.deepEqual(labelsAndEquation.labels, ["label1", "label2"]);
            assert.equal(labelsAndEquation.equation, "     \\text{hi there!} ");
        },

        "test: ContextHandler.extractEquation, wrong label": function() {
            var session = new EditSession(["\\begin{equation} \\label{ \\text{hi there!} \\end{equation}"]);
            //                               01234567890123456 78901234 56789012345678901 234567890123456
            //                               0         10         20         30        40         50
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 16, 0, 42);

            var labelsAndEquation = ContextHandler.extractEquation(session, range);

            assert.deepEqual(labelsAndEquation.labels, []);
            assert.equal(labelsAndEquation.equation, "  \\label{  \\text{hi there!} ");
        }
    }
});
