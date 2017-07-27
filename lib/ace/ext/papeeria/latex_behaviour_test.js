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

    var testInsertion = function(range, string, expectedLine, row, expectedRange) {
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
        assert.equal(editSession.getLine(curRow), expectedLine);
        if (expectedRange !== undefined && expectedRange !== null) {
            assert.range(editor.getSelectionRange(),
                expectedRange.start.row, expectedRange.start.column,
                expectedRange.end.row, expectedRange.end.column
            );
        }
    };

    var testDeletion = function(row, column, expected, expectedRow, expectedColumn) {
        var cursor = editor.getCursorPosition();
        row = row || cursor.row;
        column = column || cursor.column;
        editor.moveCursorTo(row, column);
        editor.commands.exec("backspace", editor);
        assert.equal(editSession.getLine(row), expected);
    };

    module.exports = {
        "test: auto-insert closing $ and $$": function() {
            setupSession(["", "%"]);
            testInsertion(new Range(1, 0, 1, 0), "$", "$$%", 1, new Range(1, 1, 1, 1));
            testInsertion(new Range(0, 0, 0, 0), "$", "$$", 0, new Range(0, 1, 0, 1));
            testInsertion(new Range(0, 1, 0, 1), "$", "$$$$", 0, new Range(0, 2, 0, 2));
        },

        "test: no auto-insert in comments": function() {
            setupSession(["%"]);
            testInsertion(new Range(0, 1, 0, 1), "$", "%$", 0, new Range(0, 2, 0, 2));
        },

        "test: skip closing $ and $$, empty math inside": function() {
            setupSession(["$$$$"]);
            testInsertion(new Range(0, 2, 0, 2), "$", "$$$$", 0, new Range(0, 3, 0, 3));
            testInsertion(new Range(0, 3, 0, 3), "$", "$$$$", 0, new Range(0, 4, 0, 4));
        },

        "test: surround selection with $": function() {
            setupSession(["x"]);
            testInsertion(new Range(0, 0, 0, 1), "$", "$x$", 0, new Range(0, 1, 0, 2));
        },

        "test: escaped $": function() {
            setupSession(["\\", "$\\$", "\\newline", "$\\sum$", "\\\\", "\\\\\\"]);
            testInsertion(new Range(0, 1, 0, 1), "$", "\\$", 0, new Range(0, 2, 0, 2));
            testInsertion(new Range(1, 2, 1, 2), "$", "$\\$$", 1, new Range(1, 3, 1, 3));
            testInsertion(new Range(3, 2, 3, 2), "$", "$\\$sum$", 3, new Range(3, 3, 3, 3));
            testInsertion(new Range(4, 2, 4, 2), "$", "\\\\$$", 4, new Range(4, 3, 4, 3));
            testInsertion(new Range(5, 3, 5, 3), "$", "\\\\\\$", 5, new Range(5, 4, 5, 4));
        },

        "test: skip closing $, non-empty math": function() {
            setupSession(["$$x$$"]);
            testInsertion(new Range(0, 3, 0, 3), "$", "$$x$$", 0, new Range(0, 4, 0, 4));
            testInsertion(new Range(0, 4, 0, 4), "$", "$$x$$", 0, new Range(0, 5, 0, 5));
        },

        "test: do not auto-close $ inside equation": function() {
            setupSession(["$", ""]);
            testInsertion(new Range(1, 0, 1, 0), "$", "$", 1, new Range(1, 1, 1, 1));
            setupSession(["$$  $$"]);
            testInsertion(new Range(0, 3, 0, 3), "$", "$$ $ $$", 0, new Range(0, 4, 0, 4));
        },

        "test: delete surrounding $": function() {
            setupSession(["$$$$"]);
            testDeletion(0, 2, "$$", 0, 1);
            testDeletion(0, 1, "", 0, 0);
        },

        "test: regular behaviour when deleting \\$": function() {
            setupSession(["$\\$$"]);
            testDeletion(0, 3, "$\\$", 0, 2);
        },

        "test: regular brackets insertion": function() {
            setupSession(["", "$$"]);

            testInsertion(new Range(0, 0, 0, 0), "(", "()", 0, new Range(0, 1, 0, 1));
            testInsertion(new Range(0, 1, 0, 1), "[", "([])", 0, new Range(0, 2, 0, 2));
            testInsertion(new Range(0, 2, 0, 2), "{", "([{}])", 0, new Range(0, 3, 0, 3));

            testInsertion(new Range(1, 1, 1, 1), "(", "$()$", 1, new Range(1, 2, 1, 2));
            testInsertion(new Range(1, 2, 1, 2), "[", "$([])$", 1, new Range(1, 3, 1, 3));
            testInsertion(new Range(1, 3, 1, 3), "{", "$([{}])$", 1, new Range(1, 4, 1, 4));

            setupSession(["%"]);
            testInsertion(new Range(0, 0, 0, 0), "(", "()%", 0, new Range(0, 1, 0, 1));
            setupSession(["%"]);
            testInsertion(new Range(0, 0, 0, 0), "[", "[]%", 0, new Range(0, 1, 0, 1));
            setupSession(["%"]);
            testInsertion(new Range(0, 0, 0, 0), "{", "{}%", 0, new Range(0, 1, 0, 1));
        },

        "test: surround with brackets": function() {
            setupSession(["x"]);
            testInsertion(new Range(0, 0, 0, 1), "(", "(x)", 0, new Range(0, 1, 0, 2));
            testInsertion(new Range(0, 1, 0, 2), "[", "([x])", 0, new Range(0, 2, 0, 3));
        },

        "test: surround with brackets": function() {
            setupSession(["x"]);
            testInsertion(new Range(0, 0, 0, 1), "(", "(x)", 0, new Range(0, 1, 0, 2));
            testInsertion(new Range(0, 1, 0, 2), "[", "([x])", 0, new Range(0, 2, 0, 3));
            testInsertion(new Range(0, 2, 0, 3), "{", "([{x}])", 0, new Range(0, 3, 0, 4));
        },

        "test: escaped brackets": function() {
            setupSession(["\\"]);
            testInsertion(new Range(0, 1, 0, 1), "(", "\\(\\)", 0, new Range(0, 2, 0, 2));
            setupSession(["\\"]);
            testInsertion(new Range(0, 1, 0, 1), "[", "\\[\\]", 0, new Range(0, 2, 0, 2));
            setupSession(["\\"]);
            testInsertion(new Range(0, 1, 0, 1), "{", "\\{", 0, new Range(0, 2, 0, 2));

            setupSession(["\\\\"]);
            testInsertion(new Range(0, 2, 0, 2), "(", "\\\\()", 0, new Range(0, 3, 0, 3));
            setupSession(["\\\\"]);
            testInsertion(new Range(0, 2, 0, 2), "[", "\\\\[]", 0, new Range(0, 3, 0, 3));
            setupSession(["\\\\"]);
            testInsertion(new Range(0, 2, 0, 2), "{", "\\\\{}", 0, new Range(0, 3, 0, 3));

            setupSession(["$\\$"]);
            testInsertion(new Range(0, 2, 0, 2), "(", "$\\($", 0, new Range(0, 3, 0, 3));
            setupSession(["$\\$"]);
            testInsertion(new Range(0, 2, 0, 2), "[", "$\\[$", 0, new Range(0, 3, 0, 3));
            setupSession(["$\\$"]);
            testInsertion(new Range(0, 2, 0, 2), "{", "$\\{$", 0, new Range(0, 3, 0, 3));

            setupSession(["$\\\\$"]);
            testInsertion(new Range(0, 3, 0, 3), "(", "$\\\\()$", 0, new Range(0, 4, 0, 4));
            setupSession(["$\\\\$"]);
            testInsertion(new Range(0, 3, 0, 3), "[", "$\\\\[]$", 0, new Range(0, 4, 0, 4));
            setupSession(["$\\\\$"]);
            testInsertion(new Range(0, 3, 0, 3), "{", "$\\\\{}$", 0, new Range(0, 4, 0, 4));
        },

        "test: skip closing brackets": function() {
            setupSession(["([{}])"]);
            testInsertion(new Range(0, 3, 0, 3), "}", "([{}])", 0, new Range(0, 4, 0, 4));
            testInsertion(new Range(0, 4, 0, 4), "]", "([{}])", 0, new Range(0, 5, 0, 5));
            testInsertion(new Range(0, 5, 0, 5), ")", "([{}])", 0, new Range(0, 6, 0, 6));

            setupSession(["\\(x\\)"]);
            testInsertion(new Range(0, 3, 0, 3), ")", "\\(x\\)", 0, new Range(0, 5, 0, 5));
            setupSession(["\\[x\\]"]);
            testInsertion(new Range(0, 3, 0, 3), "]", "\\[x\\]", 0, new Range(0, 5, 0, 5));
            setupSession(["\\(\\)"]);
            testInsertion(new Range(0, 2, 0, 2), ")", "\\(\\)", 0, new Range(0, 4, 0, 4));
            setupSession(["\\[\\]"]);
            testInsertion(new Range(0, 2, 0, 2), "]", "\\[\\]", 0, new Range(0, 4, 0, 4));
        },

        "test: delete brackets": function() {
            setupSession(["([{}])"]);
            editor.moveCursorTo(0, 3);
            testDeletion(null, null, "([])", 0, 2);
            testDeletion(null, null, "()", 0, 1);
            testDeletion(null, null, "", 0, 0);
        },

        "test: delete math boundaries": function() {
            setupSession(["\\(\\)"]);
            testDeletion(0, 2, "\\", 0, 1);
            setupSession(["\\[\\]"]);
            testDeletion(0, 2, "\\", 0, 1);
        }
    }
});
