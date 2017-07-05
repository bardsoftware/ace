if (typeof process !== "undefined") {
    require("amd-loader");
    require("ace/test/mockdom");
}

define(function(require, exports, module) {
    "use strict";
    var assert = require("ace/test/assertions");
    var Editor = require("ace/editor").Editor;
    var EditSession = require("ace/edit_session").EditSession;
    var MockRenderer = require("ace/test/mockrenderer").MockRenderer;
    var PapeeriaLatexMode = require("ace/mode/papeeria_latex").Mode;
    var Range = require("ace/range").Range;
    var editor;
    var editSession;
    var setupSession = function(strings) {
        editSession = new EditSession(strings, new PapeeriaLatexMode());
        editor = new Editor(new MockRenderer(), editSession);
        editor.setOption("behavioursEnabled", true);
    };

    var testInsertion = function(range, string, expected, row) {
        if (range !== null && range !== undefined) {
            editor.selection.setSelectionRange(range);
        }
        editor.commands.exec("insertstring", editor, string);
        var curRow;
        if (row !== undefined && row !== null) {
            curRow = row;
        } else {
            if (range !== undefined && range !== null) {
                curRow = range.start.row;
            } else {
                curRow = editor.getCursorPosition().row;
            }
        }
        assert.equal(editSession.getLine(curRow), expected);
    };

    var testDeletion = function(row, column, expected) {
        editor.moveCursorTo(row, column);
        editor.commands.exec("backspace", editor);
        assert.equal(editSession.getLine(row), expected);
    };

    module.exports = {
        "test: auto-insert closing $ and $$": function() {
            setupSession(["", "%"]);
            testInsertion(new Range(1, 0, 1, 0), "$", "$$%");
            testInsertion(new Range(0, 0, 0, 0), "$", "$$");
            testInsertion(new Range(0, 1, 0, 1), "$", "$$$$");
        },

        "test: no auto-insert in comments": function() {
            setupSession(["%"]);
            testInsertion(new Range(0, 1, 0, 1), "$", "%$");
        },

        "test: skip closing $ and $$, empty math inside": function() {
            setupSession(["$$$$"]);
            testInsertion(new Range(0, 2, 0, 2), "$", "$$$$");
            testInsertion(new Range(0, 3, 0, 3), "$", "$$$$");
        },

        "test: surround selection with $": function() {
            setupSession(["x"]);

            editor.navigateFileStart();
            testInsertion(new Range(0, 0, 0, 1), "$", "$x$");
            var curRange = editor.selection.getRange();
            assert.range(curRange, 0, 1, 0, 2);
        },

        "test: escaped $ in math in text": function() {
            setupSession(["\\", "$\\$", "\\newline", "$\\sum$"]);
            testInsertion(new Range(0, 1, 0, 1), "$", "\\$");
            testInsertion(new Range(1, 2, 1, 2), "$", "$\\$$");
            testInsertion(new Range(3, 2, 3, 2), "$", "$\\$sum$");
        },

        "test: auto-close $ after \\\\": function() {
            setupSession(["\\\\"]);
            testInsertion(new Range(0, 2, 0, 2), "$", "\\\\$$");
        },

        "test: skip closing $, non-empty math": function() {
            setupSession(["$$x$$"]);
            testInsertion(new Range(0, 3, 0, 3), "$", "$$x$$");
            testInsertion(new Range(0, 4, 0, 4), "$", "$$x$$");
        },

        "test: do not auto-close $ inside equation": function() {
            setupSession(["$", ""]);
            testInsertion(new Range(1, 0, 1, 0), "$", "$");
            setupSession(["$$  $$"]);
            testInsertion(new Range(0, 3, 0, 3), "$", "$$ $ $$");
        },

        "test: delete surrounding $": function() {
            setupSession(["$$$$"]);
            testDeletion(0, 2, "$$");
            testDeletion(0, 1, "");
        },

        "test: regular behaviour when deleting \\$": function() {
            setupSession(["$\\$$"]);
            testDeletion(0, 3, "$\\$");
        },

        "test: regular brackets insertion": function() {
            setupSession(["", "$$"]);

            testInsertion(new Range(0, 0, 0, 0), "(", "()");
            testInsertion(new Range(0, 1, 0, 1), "[", "([])");
            testInsertion(new Range(0, 2, 0, 2), "{", "([{}])");

            testInsertion(new Range(1, 1, 1, 1), "(", "$()$");
            testInsertion(new Range(1, 2, 1, 2), "[", "$([])$");
            testInsertion(new Range(1, 3, 1, 3), "{", "$([{}])$");

            setupSession(["%"]);
            testInsertion(new Range(0, 0, 0, 0), "(", "()%");
            setupSession(["%"]);
            testInsertion(new Range(0, 0, 0, 0), "[", "[]%");
            setupSession(["%"]);
            testInsertion(new Range(0, 0, 0, 0), "{", "{}%");
        },

        "test: surround with brackets": function() {
            setupSession(["x"]);
            testInsertion(new Range(0, 0, 0, 1), "(", "(x)");
            testInsertion(new Range(0, 1, 0, 2), "[", "([x])");
        },

        "test: surround with brackets": function() {
            setupSession(["x"]);
            testInsertion(new Range(0, 0, 0, 1), "(", "(x)");
            testInsertion(new Range(0, 1, 0, 2), "[", "([x])");
            testInsertion(new Range(0, 2, 0, 3), "{", "([{x}])");
        },

        "test: escaped brackets": function() {
            setupSession(["\\"]);
            testInsertion(new Range(0, 1, 0, 1), "(", "\\(\\)");
            setupSession(["\\"]);
            testInsertion(new Range(0, 1, 0, 1), "[", "\\[\\]");
            setupSession(["\\"]);
            testInsertion(new Range(0, 1, 0, 1), "{", "\\{");

            setupSession(["\\\\"]);
            testInsertion(new Range(0, 2, 0, 2), "(", "\\\\()");
            setupSession(["\\\\"]);
            testInsertion(new Range(0, 2, 0, 2), "[", "\\\\[]");
            setupSession(["\\\\"]);
            testInsertion(new Range(0, 2, 0, 2), "{", "\\\\{}");

            setupSession(["$\\$"]);
            testInsertion(new Range(0, 2, 0, 2), "(", "$\\($");
            setupSession(["$\\$"]);
            testInsertion(new Range(0, 2, 0, 2), "[", "$\\[$");
            setupSession(["$\\$"]);
            testInsertion(new Range(0, 2, 0, 2), "{", "$\\{$");

            setupSession(["$\\\\$"]);
            testInsertion(new Range(0, 3, 0, 3), "(", "$\\\\()$");
            setupSession(["$\\\\$"]);
            testInsertion(new Range(0, 3, 0, 3), "[", "$\\\\[]$");
            setupSession(["$\\\\$"]);
            testInsertion(new Range(0, 3, 0, 3), "{", "$\\\\{}$");
        },

        "test: skip closing brackets": function() {
            setupSession(["([{}])"]);
            testInsertion(new Range(0, 3, 0, 3), "}", "([{}])");
            testInsertion(null, "]", "([{}])");
            testInsertion(null, ")", "([{}])");

            setupSession(["\\(x\\)"]);
            testInsertion(new Range(0, 3, 0, 3), ")", "\\(x\\)");
            setupSession(["\\[x\\]"]);
            testInsertion(new Range(0, 3, 0, 3), "]", "\\[x\\]");
        }
    }
});
