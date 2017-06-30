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
            var editSession = new EditSession([""], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.navigateFileStart();
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$$", "Should insert closing $");
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$$$$", "Should insert closing $$");
        },

        "test: skip closing $ and $$, empty math inside": function() {
            var editSession = new EditSession(["$$$$"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 2);
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$$$$", "Should skip first closing $");
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$$$$", "Should skip second closing $");
        },

        "test: surround selection with $": function() {
            var editSession = new EditSession(["x"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.navigateFileStart();
            editor.selection.setSelectionRange(new Range(0, 0, 0, 1));
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$x$", "Should surround string with $");
            var curRange = editor.selection.getRange();
            assert.range(curRange, 0, 1, 0, 2);
        },

        "test: escaped $ in math in text": function() {
            var editSession = new EditSession(["\\", "$\\$"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 1);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(0), "\\$", "Should not auto-close escaped $ in text");
            editor.moveCursorTo(1, 2);
            exec("insertstring", 1, "$");
            assert.equal(editSession.getLine(1), "$\\$$", "Should not auto-close escaped $ in math");
        },

        "test: skip closing $, non-empty math": function() {
            var editSession = new EditSession(["$$x$$"], new PapeeriaLatexMode());
            editor = new Editor(new MockRenderer(), editSession);
            editor.setOption("behavioursEnabled", true);

            editor.moveCursorTo(0, 3);
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$$x$$", "Should skip first closing $");
            exec("insertstring", 1, "$");
            assert.equal(editor.getValue(), "$$x$$", "Should skip second closing $");
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
            // assert.equal(editSession.getLine(1), "$$");
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
    }
});
