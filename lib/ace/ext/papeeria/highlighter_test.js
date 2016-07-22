define(function(require, exports, module) {

    var EditSession = require("ace/edit_session").EditSession;
    var Editor = require("ace/editor").Editor;
    var MockRenderer = require("ace/test/mockrenderer").MockRenderer;
    var assert = require("ace/test/assertions");
    var highlighter = require("ace/ext/papeeria/highlighter");
    var Range = require("ace/range").Range

    getRangeHighlightText = function(session) {
        var allMarkers = session.getMarkers();
        for (var key in allMarkers) 
           if (allMarkers[key].clazz == "ace_error-marker")
              return allMarkers[key].range
        return null
    }

    getPositionHighlightText = function(session) {
        var allMarkers = session.getMarkers();
        var leftBracket;
        for(var key in allMarkers)
            if (allMarkers[key].clazz == "ace_bracket")
                if (!leftBracket) 
                    leftBracket = allMarkers[key].range.end
                else 
                    return {left: leftBracket, right: allMarkers[key].range.end}
        return null;
    }

    module.exports = {
        "test: has not opening bracket, cursor before closing bracket": function() {
            var session = new EditSession(["some_Text}"].join("\n"));
            var editor = new Editor(new MockRenderer(), session);

            editor.moveCursorTo(0,1);

            highlighter.highlightBrackets(editor);

            console.log(getRangeHighlightText(session));
            assert.range(getRangeHighlightText(session), 0, 0, 0, 10);
        },

        "test: has not opening bracket, cursor after closing bracket": function() {
            var session = new EditSession(["someText}_"].join("\n"));
            var editor = new Editor(new MockRenderer(), session);

            editor.moveCursorTo(0,9);

            highlighter.highlightBrackets(editor);

            assert.equal(getRangeHighlightText(session), null);
        },

        "test: has not closing bracket, cursor after opening bracket": function() {
            var session = new EditSession(["{some_Text"].join("\n"));
            var editor = new Editor(new MockRenderer(), session);

            editor.moveCursorTo(0,6);

            highlighter.highlightBrackets(editor);

            assert.range(getRangeHighlightText(session), 0, 0, Infinity, Infinity);
        },

        "test: has not closing bracket, cursor before opening bracket": function() {
            var session = new EditSession(["_{someText"].join("\n"));
            var editor = new Editor(new MockRenderer(), session);

            editor.moveCursorTo(0,0);

            highlighter.highlightBrackets(editor);

            assert.equal(getRangeHighlightText(session), null);
        },

        "test: no mismatch, cursor between brackets": function() {
            var session = new EditSession(["{some_Text}"].join("\n"));
            var editor = new Editor(new MockRenderer(), session);

            editor.moveCursorTo(0, 4);

            highlighter.highlightBrackets(editor);
            result = getPositionHighlightText(session);

            assert.position(result.left, 0, 1);
            assert.position(result.right, 0, 11);
        },

        "test: no mismatch, cursor next position after left bracket": function() {
            var session = new EditSession(["{_someText}"].join("\n"));
            var editor = new Editor(new MockRenderer(), session);

            editor.moveCursorTo(0, 1);

            highlighter.highlightBrackets(editor);
            result = getPositionHighlightText(session);

            assert.position(result.left, 0, 1);
            assert.position(result.right, 0, 11);
        },

        "test: no mismatch, cursor cursor next position before right bracket": function() {
            var session = new EditSession(["{someText_}"]);
            var editor = new Editor(new MockRenderer(), session);

            editor.moveCursorTo(0, 10);

            highlighter.highlightBrackets(editor);
            result = getPositionHighlightText(session);

            assert.position(result.left, 0, 1);
            assert.position(result.right, 0, 11);
        },

        "test: no mismatch, cursor before left bracket": function() {
            var session = new EditSession(["_{some text}"].join("\n"));
            var editor = new Editor(new MockRenderer(), session);

            editor.moveCursorTo(0,0);

            highlighter.highlightBrackets(editor);

            assert.equal(getRangeHighlightText(session), null);
        },

        "test: no mismatch, cursor after right bracket": function() {
            var session = new EditSession(["{someText}_"]);
            var editor = new Editor(new MockRenderer(), session);

            editor.moveCursorTo(0, 11);

            highlighter.highlightBrackets(editor);

            assert.equal(getRangeHighlightText(session), null);
        }
    }
});