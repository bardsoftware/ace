if (typeof process !== "undefined") {
    require("amd-loader");
    require("../../test/mockdom");
}


define(function(require, exports, module) {
    var assert = require("ace/test/assertions");
    var ConstrainedTokenIterator = require("ace/ext/papeeria/constrained_token_iterator").ConstrainedTokenIterator;
    var EditSession = require("ace/edit_session").EditSession;
    var Editor = require("ace/editor").Editor;
    var MockRenderer = require("ace/test/mockrenderer").MockRenderer;
    var Range = require("ace/range").Range

    module.exports = {
        "test: basic forward": function() {
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

        "test: basic backward": function() {
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

        "test: forward several times": function() {
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

        "test: backward several times": function() {
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

        "test: exact range": function() {
            var session = new EditSession(["\\newline \\newline \\newline"]);
            //                               012345678 901234567 890123456
            //                               0          10         20
            var editor = new Editor(new MockRenderer(), session);
            session.setMode("./mode/papeeria_latex");

            var range = new Range(0, 9, 0, 17);
            var tokenIterator = new ConstrainedTokenIterator(session, range, 0, 10);
            assert.notEqual(tokenIterator.getCurrentToken(), null);
        },

        "test: starting out of range": function() {
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
