define(function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var Mirror = require("../worker/mirror").Mirror;
var Tokenizer = require("../tokenizer").Tokenizer;
var BackgroundTokenizer = require("../background_tokenizer").BackgroundTokenizer;

var TextParser = require("./text_parser").TextParser;
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;


var WORKER_TIMEOUT_MS = 20;


var PapeeriaWorker = exports.PapeeriaWorker = function(sender) {
    Mirror.call(this, sender);
    this.setTimeout(WORKER_TIMEOUT_MS);
    this.mySpellingCheckOptions = {};
    this.myTypos = {};
    var highlighter = new TextHighlightRules();
    this.myBgTokenizer = new BackgroundTokenizer(new Tokenizer(highlighter.getRules()));
    this.myBgTokenizer.setDocument(this.doc);
    this.myBgTokenizer.start(0);
    this.myParser = new TextParser(this.myBgTokenizer);
};

oop.inherits(PapeeriaWorker, Mirror);


(function() {

    this.updateSpellcheckingTypos = function(newTypos) {
        this.myTypos = newTypos;
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
            this.myParser.setSpellingCheckDictionary(this.myTypos, this.mySpellingCheckOptions.punctuation);
            this.myBgTokenizer.setDocument(this.doc);
            this.myParser.go(this.doc);
            this.sender.emit("spellcheck", this.myParser.getErrors());
        } else {
            this.sender.emit("spellcheck", []);
        }
    };

}).call(PapeeriaWorker.prototype);

});
