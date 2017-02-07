define(function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var Tokenizer = require("../tokenizer").Tokenizer;
var BackgroundTokenizer = require("../background_tokenizer").BackgroundTokenizer;

var PapeeriaWorker = require("./papeeria_worker").PapeeriaWorker;
var TextParser = require("./text_parser").TextParser;
var MarkdownHighlightRules = require("./markdown_highlight_rules").MarkdownHighlightRules;


var MarkdownWorker = exports.MarkdownWorker = function(sender) {
    PapeeriaWorker.call(this, sender);
    var highlighter = new MarkdownHighlightRules();
    this.myBgTokenizer = new BackgroundTokenizer(new Tokenizer(highlighter.getRules()));
    this.myBgTokenizer.setDocument(this.doc);
    this.myBgTokenizer.start(0);
    this.myParser = new TextParser(this.myBgTokenizer);
};

oop.inherits(MarkdownWorker, PapeeriaWorker);

});
