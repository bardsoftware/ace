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
    }

    var testInsertion = function(row, column, string, expected) {
        editor.moveCursorTo(row, column);
        editor.commands.exec("insertstring", editor, string);
        assert.equal(editSession.getLine(row), expected);
    }

    var testDeletion = function(row, column, expected) {
        editor.moveCursorTo(row, column);
        editor.commands.exec("backspace", editor);
        assert.equal(editSession.getLine(row), expected);
    }

    module.exports = {
        "test: auto-insert closing $ and $$": function() {
            setupSession(["", "%"]);
            testInsertion(1, 0, "$", "$$%");
            testInsertion(0, 0, "$", "$$");
            testInsertion(0, 1, "$", "$$$$");
        },

        "test: no auto-insert in comments": function() {
            setupSession(["%"]);
            testInsertion(0, 1, "$", "%$");
        },

        "test: skip closing $ and $$, empty math inside": function() {
            setupSession(["$$$$"]);
            testInsertion(0, 2, "$", "$$$$");
            testInsertion(0, 3, "$", "$$$$");
        },

        "test: surround selection with $": function() {
            setupSession(["x"]);

            editor.navigateFileStart();
            editor.selection.setSelectionRange(new Range(0, 0, 0, 1));
            editor.commands.exec("insertstring", editor, "$");
            assert.equal(editor.getValue(), "$x$");
            var curRange = editor.selection.getRange();
            assert.range(curRange, 0, 1, 0, 2);
        },

        "test: escaped $ in math in text": function() {
            setupSession(["\\", "$\\$", "\\newline", "$\\sum$"]);
            testInsertion(0, 1, "$", "\\$");
            testInsertion(1, 2, "$", "$\\$$");
            testInsertion(3, 2, "$", "$\\$sum$");
        },

        "test: auto-close $ after \\\\": function() {
            setupSession(["\\\\"]);
            testInsertion(0, 2, "$", "\\\\$$");
        },

        "test: skip closing $, non-empty math": function() {
            setupSession(["$$x$$"]);
            testInsertion(0, 3, "$", "$$x$$");
            testInsertion(0, 4, "$", "$$x$$");
        },

        "test: do not auto-close $ inside equation": function() {
            setupSession(["$", ""]);
            testInsertion(1, 0, "$", "$");
            setupSession(["$$  $$"]);
            testInsertion(0, 3, "$", "$$ $ $$");
        },

        "test: delete surrounding $": function() {
            setupSession(["$$$$"]);
            testDeletion(0, 2, "$$");
            testDeletion(0, 1, "");
        },

        "test: regular behaviour when deleting \\$": function() {
            setupSession(["$\\$$"]);
            testDeletion(0, 3, "$\\$");
        }
    }
});
