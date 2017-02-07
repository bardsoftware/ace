define(function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var Tokenizer = require("../tokenizer").Tokenizer;
var BackgroundTokenizer = require("../background_tokenizer").BackgroundTokenizer;

var PapeeriaWorker = require("./papeeria_worker").PapeeriaWorker;

var LatexParser = require("./latex_parser").LatexParser;
var LatexHighlightRules = require("./latex_highlight_rules").LatexHighlightRules;

var WORKER_TIMEOUT_MS = 20;

var LatexWorker = exports.LatexWorker = function(sender) {
    PapeeriaWorker.call(this, sender);
    this.myDiscussionsOptions = {};
    var highlighter = new LatexHighlightRules();
    this.myBgTokenizer = new BackgroundTokenizer(new Tokenizer(highlighter.getRules()));
    this.myBgTokenizer.setDocument(this.doc);
    this.myBgTokenizer.start(0);
    this.myParser = new LatexParser(this.myBgTokenizer);
};

oop.inherits(LatexWorker, PapeeriaWorker);

(function() {

    this.changeDiscussionsOptions = function(newOptions) {
        this.myDiscussionsOptions = newOptions;
        this.sender.emit("discussionsSettingsUpdateSuccess", []);
        this.deferredUpdate.schedule(WORKER_TIMEOUT_MS);
    };

    this.onUpdate = function() {
        var doSpellcheck = false,
            doGetDiscussions = false;

        if (this.doc.getValue()) {
            doGetDiscussions = this.myDiscussionsOptions.enabled;

            if (this.mySpellingCheckOptions.enabled) {
                doSpellcheck = true;
                this.myParser.setSpellingCheckDictionary(this.myTypos, this.mySpellingCheckOptions.alphabet);
            } else {
                doSpellcheck = false;
                this.sender.emit("spellcheck", []);
            }

            this.myBgTokenizer.setDocument(this.doc);
            this.myParser.go(this.doc, {
                spellcheck: doSpellcheck,
                parseDiscussions: doGetDiscussions,
                lineCommentSymbol: this.myDiscussionsOptions.lineCommentSymbol
            });

            doSpellcheck && this.sender.emit("spellcheck", this.myParser.getErrors());
            doGetDiscussions && this.sender.emit("discussions", this.myParser.getDiscussions());
        }
    };

}).call(LatexWorker.prototype);

});
