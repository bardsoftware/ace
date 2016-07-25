if (typeof process !== "undefined") {
    require("amd-loader");
    require("../../test/mockdom");
}

define(function(require, exports, module) {

    var EditSession = require("../../edit_session").EditSession;
    var Editor = require("../../editor").Editor;
    var MockRenderer = require("../../test/mockrenderer").MockRenderer;
    var assert = require("../../test/assertions");
    var highlighter = require("../../ext/papeeria/highlighter");
    var Range = require("../../range").Range

    var getMismatchRangeHighlightingText = function(session) {
        var allMarkers = session.getMarkers();
        for (var key in allMarkers) 
           if (allMarkers[key].clazz == "ace_error-marker")
              return allMarkers[key].range
        return null
    }

    var getMatchRangeHighlightingText = function(session) {
        var allMarkers = session.getMarkers();
        var leftBracket;
        for (var key in allMarkers)
            if (allMarkers[key].clazz == "ace_bracket")
                if (!leftBracket) 
                    leftBracket = allMarkers[key].range.end
                else 
                    return {left: leftBracket, right: allMarkers[key].range.end}
        return null;
    }
    //*******
    //We need to set latex mode to tokenize text properly, despite that tests may pass when editor contains just a single line
    //
    //********
    module.exports = {
        "test: has no opening bracket, cursor before closing bracket": function() {
            var session = new EditSession(["some_Text}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(0,1);

            highlighter.highlightBrackets(editor);

            assert.range(getMismatchRangeHighlightingText(session), 0, 0, 0, 10);
        },

        "test: has no opening bracket, cursor next position after closing bracket": function() {
            var session = new EditSession(["someText}_"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(0,9);

            highlighter.highlightBrackets(editor);

            assert.range(getMismatchRangeHighlightingText(session), 0, 0, 0 ,9);
        },

        "test: has no opening bracket, cursor after closing bracket": function() {
            var session = new EditSession(["someText}text_"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(0,13);

            highlighter.highlightBrackets(editor);

            assert.equal(getMismatchRangeHighlightingText(session), null);
        },

        "test: has no closing bracket, cursor after opening bracket": function() {
            var session = new EditSession(["{some_Text"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(0,6);

            highlighter.highlightBrackets(editor);

            assert.range(getMismatchRangeHighlightingText(session), 0, 0, Infinity, Infinity);
        },

        "test: has no closing bracket, cursor before opening bracket": function() {
            var session = new EditSession(["_{someText"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(0,0);

            highlighter.highlightBrackets(editor);

            assert.equal(getMismatchRangeHighlightingText(session), null);
        },

        "test: no mismatch, cursor between brackets": function() {
            var session = new EditSession(["{some_Text}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(0, 4);

            highlighter.highlightBrackets(editor);
            var result = getMatchRangeHighlightingText(session);

            assert.position(result.left, 0, 1);
            assert.position(result.right, 0, 11);
        },

        "test: no mismatch, cursor next position after left bracket": function() {
            var session = new EditSession(["{_someText}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(0, 1);

            highlighter.highlightBrackets(editor);
            var result = getMatchRangeHighlightingText(session);

            assert.position(result.left, 0, 1);
            assert.position(result.right, 0, 11);
        },

        "test: no mismatch, cursor cursor next position before right bracket": function() {
            var session = new EditSession(["{someText_}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(0, 10);

            highlighter.highlightBrackets(editor);
            var result = getMatchRangeHighlightingText(session);

            assert.position(result.left, 0, 1);
            assert.position(result.right, 0, 11);
        },

        "test: no mismatch, cursor before left bracket": function() {
            var session = new EditSession(["_someText{some text}"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(0,0);

            highlighter.highlightBrackets(editor);

            assert.equal(getMismatchRangeHighlightingText(session), null);
        },

        "test: no mismatch, cursor after right bracket": function() {
            var session = new EditSession(["{someText}someText_"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(0, 11);

            highlighter.highlightBrackets(editor);

            assert.equal(getMismatchRangeHighlightingText(session), null);
        },

        "test: mismatch, multiline, has no closing bracket, cursor after opening bracket": function() {
            var session = new EditSession(["{someText", "moreSomeText"]);
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(1,1);

            highlighter.highlightBrackets(editor);

            assert.range(getMismatchRangeHighlightingText(session), 0, 0, Infinity, Infinity);
        },

        "test: no mismatch, multiline, cursor between brackets": function() {
            var session = new EditSession(["{someText", "moreSomeText}"])
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            editor.moveCursorTo(1,1);

            highlighter.highlightBrackets(editor);
            var result = getMatchRangeHighlightingText(session);

            assert.position(result.left, 0, 1);
            assert.position(result.right, 1, 13);
        }

    }
});