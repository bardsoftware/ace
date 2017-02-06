define(function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var Mirror = require("../worker/mirror").Mirror;
var Tokenizer = require("../tokenizer").Tokenizer;
var BackgroundTokenizer = require("../background_tokenizer").BackgroundTokenizer;

var TextParser = require("./text_parser").TextParser;
var MarkdownHighlightRules = require("./markdown_highlight_rules").MarkdownHighlightRules;


var WORKER_TIMEOUT_MS = 20;


var makeSet = function(array) {
    var tmp = {};
    for (var i = 0; i < array.length; i++) {
        tmp[array[i]] = true;
    }
    return tmp;
};


var MarkdownWorker = exports.MarkdownWorker = function(sender) {
    Mirror.call(this, sender);
    this.setTimeout(WORKER_TIMEOUT_MS);
    this.mySpellingCheckOptions = {};
    this.myTypos = {};
    var highlighter = new MarkdownHighlightRules();
    this.myBgTokenizer = new BackgroundTokenizer(new Tokenizer(highlighter.getRules()));
    this.myBgTokenizer.setDocument(this.doc);
    this.myBgTokenizer.start(0);
    this.myParser = new TextParser(this.myBgTokenizer);
};

oop.inherits(MarkdownWorker, Mirror);


(function() {

    this.updateSpellcheckingTypos = function(newTypos) {
        this.myTypos = makeSet(newTypos);
        this.deferredUpdate.schedule(WORKER_TIMEOUT_MS);
    };

    this.changeSpellingCheckOptions = function(newOptions) {
        oop.mixin(this.mySpellingCheckOptions, newOptions);

        if (newOptions.enabled) {
            this.deferredUpdate.schedule(WORKER_TIMEOUT_MS);
        }
    };

    this.onUpdate = function() {
        if (!this.doc.getValue()) {
            return;
        }
        if (this.mySpellingCheckOptions.enabled) {
            this.myParser.setSpellingCheckDictionary(this.myTypos, this.mySpellingCheckOptions.alphabet);
            this.myBgTokenizer.setDocument(this.doc);
            this.myParser.go(this.doc);
            this.sender.emit("spellcheck", this.myParser.getErrors());
        } else {
            this.sender.emit("spellcheck", []);
        }
    };

}).call(MarkdownWorker.prototype);

});
