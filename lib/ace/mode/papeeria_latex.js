define(function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var Tokenizer = require("../tokenizer").Tokenizer;
var LatexHighlightRules = require("../ext/papeeria/papeeria_latex_highlight_rules").PapeeriaLatexHighlightRules;
var LatexFoldMode = require("./folding/latex").FoldMode;
var Range = require("../range").Range;
var WorkerClient = require("../worker/worker_client").WorkerClient;

var Mode = function() {
    this.HighlightRules = LatexHighlightRules;
    this.foldingRules = new LatexFoldMode();
};
oop.inherits(Mode, TextMode);


(function() {
    this.lineCommentStart = "%";

    var myDiscussionsCallbacks = {
        onSuccess: null
    };

    this.createWorker = function(session) {
        var worker = new WorkerClient(["ace"], "ace/mode/latex_worker", "LatexWorker");
        worker.attachToDocument(session.getDocument());

        worker.on("discussionsSettingsUpdateSuccess", function(result) {
            myDiscussionsCallbacks.onSuccess();
        });

        worker.on("discussions", function(discussions) {
            if (myDiscussionsCallbacks.onSuccess != null) {
                myDiscussionsCallbacks.onSuccess({
                  discussions: discussions,
                  lineCommentSymbol: this.lineCommentStart
                });
            }
        }.bind(this));

        var onChangeDiscussions = function(data) {
            myDiscussionsCallbacks = {
                onSuccess: data.onSuccess
            };
            worker.call("changeDiscussionsOptions", [{
                enabled: data.enabled,
                lineCommentSymbol: this.lineCommentStart
            }]);
        }.bind(this);

        worker.on("terminate", function() {
            session.off("changeDiscussionsSettings", onChangeDiscussions);
        });
        session.on("changeDiscussionsSettings", onChangeDiscussions);

        this.setupSpellchecker(worker, session);

        return worker;
    };

}).call(Mode.prototype);

exports.Mode = Mode;

});
