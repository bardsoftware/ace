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
    var exec = function(name, times, args) {
        do {
            editor.commands.exec(name, editor, args);
        } while(times --> 1);
    };

    module.exports = {
        "test: auto-insert closing $ and $$": function() {
            var editSession = new EditSession(["", "%"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(1, 0);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(1), "$$%")

            editor.navigateFileStart();
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(0), "$$");
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(0), "$$$$");
        },

        "test: no auto-insert in comments": function() {
            var editSession = new EditSession(["%"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 1);
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "%$");
        },

        "test: skip closing $ and $$, empty math inside": function() {
            var editSession = new EditSession(["$$$$"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 2);
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$$$$");
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$$$$");
        },

        "test: surround selection with $": function() {
            var editSession = new EditSession(["x"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.navigateFileStart();
            editor.selection.setSelectionRange(new Range(0, 0, 0, 1));
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$x$");
            var curRange = editor.selection.getRange();
            assert.range(curRange, 0, 1, 0, 2);
        },

        "test: escaped $ in math in text": function() {
            var editSession = new EditSession(["\\", "$\\$", "\\newline", "$\\sum$"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 1);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(0), "\\$");

            editor.moveCursorTo(1, 2);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(1), "$\\$$");

            editor.moveCursorTo(2, 1);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(2), "\\$newline");

            editor.moveCursorTo(3, 2);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(3), "$\\$sum$");
        },

        "test: auto-close $ after \\\\": function() {
            var editSession = new EditSession(["\\\\"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 2);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(0), "\\\\$$");
        },

        "test: skip closing $, non-empty math": function() {
            var editSession = new EditSession(["$$x$$"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 3);
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$$x$$");
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$$x$$");
        },

        "test: do not auto-close $ inside equation": function() {
            var editSession = new EditSession(
                ["$$  $$", "$", "", "$", ""],
                new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 3);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(0), "$$ $ $$");
            exec("backspace", 1);

            editor.moveCursorTo(1, 1);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(1), "$$");

            editor.moveCursorTo(4, 0);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(4), "$");
        },

        "test: do not auto-close $ inside equation": function() {
            var editSession = new EditSession(["$$  $$", "$ ", "smth"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 3);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(0), "$$ $ $$");
            exec("backspace", 1);

            editor.moveCursorTo(1, 1);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(1), "$$ ");
        },

        "test: delete surrounding $": function() {
            var editSession = new EditSession(["$$$$"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 2);
            exec("backspace", 1);
            assert.equal(editor.getValue(), "$$");
            exec("backspace", 1);
            assert.equal(editor.getValue(), "");
        },

        "test: regular behaviour when deleting \\$": function() {
            var editSession = new EditSession(["$\\$$"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 3);
            exec("backspace", 1);
            assert.equal(editor.getValue(), "$\\$");
        },
    }
});
